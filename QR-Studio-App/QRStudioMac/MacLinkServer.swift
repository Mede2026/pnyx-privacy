import AppKit
import ApplicationServices
import Foundation
import Network
import Observation
import OSLog
import QRCore

/// Côté Mac : reçoit les scans de l'iPhone appairé et les dépose selon le mode choisi.
@MainActor
@Observable
final class MacLinkServer {
    enum Mode: String, CaseIterable, Identifiable {
        /// Le contenu remplace le presse-papier.
        case clipboard
        /// Le contenu s'ajoute à la liste « Scans reçus », exportable en CSV.
        case list
        /// Le contenu est tapé dans le champ actif, suivi d'une tabulation ou d'un retour.
        case typing

        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .clipboard: "Presse-papier"
            case .list: "Liste"
            case .typing: "Frappe automatique"
            }
        }
    }

    enum Suffix: String, CaseIterable, Identifiable {
        case none, tab, newline
        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .none: "Rien"
            case .tab: "Tabulation"
            case .newline: "Retour"
            }
        }
    }

    struct Received: Identifiable, Codable {
        var id = UUID()
        let message: MacLinkMessage
    }

    private static let identityAccount = "mac-identity"

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "macLinkEnabled")
            isEnabled ? start() : stop()
        }
    }
    var mode: Mode { didSet { UserDefaults.standard.set(mode.rawValue, forKey: "macLinkMode") } }
    var suffix: Suffix { didSet { UserDefaults.standard.set(suffix.rawValue, forKey: "macLinkSuffix") } }
    private(set) var identity: MacLinkPairing?
    /// Liste « Scans reçus », conservée d'une ouverture à l'autre jusqu'à « Tout effacer ».
    private(set) var received: [Received] = [] {
        didSet { ReceivedScansStore.save(received) }
    }
    private(set) var connectedCount = 0
    private(set) var lastError: String?

    @ObservationIgnored private var listener: NWListener?
    @ObservationIgnored private var connections: [ObjectIdentifier: NWConnection] = [:]
    @ObservationIgnored private var buffers: [ObjectIdentifier: Data] = [:]
    @ObservationIgnored private let queue = DispatchQueue(label: "app.qrstudio.maclink.server")

    init() {
        let defaults = UserDefaults.standard
        isEnabled = defaults.bool(forKey: "macLinkEnabled")
        mode = Mode(rawValue: defaults.string(forKey: "macLinkMode") ?? "") ?? .clipboard
        suffix = Suffix(rawValue: defaults.string(forKey: "macLinkSuffix") ?? "") ?? .tab
        identity = MacLinkKeychain.load(MacLinkPairing.self, account: Self.identityAccount)
        received = ReceivedScansStore.load()
        if isEnabled { start() }
    }

    /// Nom affiché sur l'iPhone : « Mac de Médéric ».
    static var macName: String {
        Host.current().localizedName ?? String(localized: "Mac")
    }

    /// Crée l'identité à la première utilisation ; « Réinitialiser » en crée une nouvelle (les iPhone devront se réappairer).
    func ensureIdentity(reset: Bool = false) {
        guard identity == nil || reset else { return }
        do {
            let pairing = try MacLinkPairing.generate(name: Self.macName)
            try MacLinkKeychain.save(pairing, account: Self.identityAccount)
            identity = pairing
            if isEnabled {
                stop()
                start()
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Écoute

    private func start() {
        ensureIdentity()
        guard listener == nil, let identity else { return }
        do {
            let listener = try NWListener(using: MacLinkNetwork.parameters(key: identity.key))
            // Le nom de service est l'identifiant du Mac : l'iPhone ne retient que les Mac appairés.
            listener.service = NWListener.Service(name: identity.id.uuidString, type: MacLinkNetwork.serviceType)
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in self?.accept(connection) }
            }
            listener.stateUpdateHandler = { [weak self] state in
                if case .failed(let error) = state {
                    Task { @MainActor in self?.lastError = error.localizedDescription }
                }
            }
            listener.start(queue: queue)
            self.listener = listener
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func stop() {
        listener?.cancel()
        listener = nil
        for connection in connections.values { connection.cancel() }
        connections = [:]
        buffers = [:]
        connectedCount = 0
    }

    private func accept(_ connection: NWConnection) {
        let key = ObjectIdentifier(connection)
        connections[key] = connection
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .ready: self.connectedCount = self.connections.count
                case .failed, .cancelled:
                    self.connections[key] = nil
                    self.buffers[key] = nil
                    self.connectedCount = self.connections.count
                default: break
                }
            }
        }
        connection.start(queue: queue)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                guard let self else { return }
                if let data { self.consume(data, from: connection) }
                if isComplete || error != nil {
                    connection.cancel()
                } else {
                    self.receive(on: connection)
                }
            }
        }
    }

    /// Une ligne JSON par scan.
    private func consume(_ data: Data, from connection: NWConnection) {
        let key = ObjectIdentifier(connection)
        var buffer = (buffers[key] ?? Data()) + data
        while let newline = buffer.firstIndex(of: 0x0A) {
            let line = buffer[buffer.startIndex..<newline]
            buffer = Data(buffer[buffer.index(after: newline)...])
            do {
                deliver(try MacLinkMessage.decode(line: Data(line)))
            } catch {
                Logger.general.error("Message de l’iPhone illisible : \(error.localizedDescription)")
            }
        }
        buffers[key] = buffer
    }

    // MARK: - Dépôt selon le mode

    private func deliver(_ message: MacLinkMessage) {
        received.insert(Received(message: message), at: 0)
        switch mode {
        case .clipboard:
            Pasteboard.copy(message.payload)
        case .list:
            break
        case .typing:
            guard KeyboardTyper.isTrusted else {
                lastError = String(localized: "La frappe automatique demande l’autorisation Accessibilité.")
                Pasteboard.copy(message.payload)
                return
            }
            KeyboardTyper.type(message.payload, suffix: suffix)
        }
        NSSound(named: "Tink")?.play()
    }

    func clearReceived() {
        received = []
    }
}
