import Foundation
import Network
import Observation
import OSLog
import QRCore

/// Côté iPhone : trouve les Mac appairés sur le réseau local et leur envoie les scans.
/// L'envoi ne s'active que d'un geste sur la puce du scanner, et reste visible tant qu'il est actif.
@MainActor
@Observable
final class MacLinkClient {
    enum State: Equatable {
        case idle
        case connecting
        case connected
        case failed(String)
    }

    private static let pairingsAccount = "pairings"

    private(set) var pairings: [MacLinkPairing] = []
    /// Mac appairés actuellement visibles sur le réseau.
    private(set) var available: [MacLinkPairing] = []
    private(set) var activeMac: MacLinkPairing?
    private(set) var state: State = .idle

    @ObservationIgnored private var browser: NWBrowser?
    @ObservationIgnored private var connection: NWConnection?
    @ObservationIgnored private var endpoints: [UUID: NWEndpoint] = [:]
    @ObservationIgnored private let queue = DispatchQueue(label: "app.qrstudio.maclink.client")

    init() {
        pairings = MacLinkKeychain.load([MacLinkPairing].self, account: Self.pairingsAccount) ?? []
    }

    var isSending: Bool { state == .connected }

    // MARK: - Appairage

    func pair(_ pairing: MacLinkPairing) throws {
        pairings.removeAll { $0.id == pairing.id }
        pairings.append(pairing)
        try MacLinkKeychain.save(pairings, account: Self.pairingsAccount)
        restartBrowsing()
    }

    func forget(_ pairing: MacLinkPairing) {
        if activeMac?.id == pairing.id { disconnect() }
        pairings.removeAll { $0.id == pairing.id }
        do {
            try MacLinkKeychain.save(pairings, account: Self.pairingsAccount)
        } catch {
            Logger.general.error("Appairage non oublié : \(error.localizedDescription)")
        }
        available.removeAll { $0.id == pairing.id }
    }

    // MARK: - Découverte (seulement pendant que le scanner est visible)

    func setBrowsing(_ active: Bool) {
        if active { startBrowsing() } else { stopBrowsing() }
    }

    private func restartBrowsing() {
        guard browser != nil else { return }
        stopBrowsing()
        startBrowsing()
    }

    private func startBrowsing() {
        guard browser == nil, !pairings.isEmpty else { return }
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: MacLinkNetwork.serviceType, domain: nil), using: parameters)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            let found: [(String, NWEndpoint)] = results.compactMap { result in
                if case .service(let name, _, _, _) = result.endpoint { return (name, result.endpoint) }
                return nil
            }
            Task { @MainActor in self?.update(found) }
        }
        browser.start(queue: queue)
        self.browser = browser
    }

    private func stopBrowsing() {
        browser?.cancel()
        browser = nil
        if !isSending { available = [] }
    }

    /// Le nom de service Bonjour est l'identifiant du Mac : seuls les Mac appairés sont retenus.
    private func update(_ found: [(String, NWEndpoint)]) {
        endpoints = [:]
        for (name, endpoint) in found {
            if let id = UUID(uuidString: name) { endpoints[id] = endpoint }
        }
        available = pairings.filter { endpoints[$0.id] != nil }
    }

    // MARK: - Connexion

    func toggle(_ mac: MacLinkPairing) {
        if activeMac?.id == mac.id, state != .idle {
            disconnect()
        } else {
            connect(to: mac)
        }
    }

    private func connect(to mac: MacLinkPairing) {
        disconnect()
        guard let endpoint = endpoints[mac.id] else { return }
        let connection = NWConnection(to: endpoint, using: MacLinkNetwork.parameters(key: mac.key))
        connection.stateUpdateHandler = { [weak self] newState in
            Task { @MainActor in self?.handle(newState) }
        }
        activeMac = mac
        state = .connecting
        self.connection = connection
        connection.start(queue: queue)
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        activeMac = nil
        state = .idle
    }

    private func handle(_ newState: NWConnection.State) {
        switch newState {
        case .ready:
            state = .connected
        case .failed(let error), .waiting(let error):
            Logger.general.error("Liaison Mac : \(error.localizedDescription)")
            connection?.cancel()
            connection = nil
            state = .failed(String(localized: "Connexion au Mac impossible"))
        case .cancelled:
            if state != .idle { state = .idle }
        default:
            break
        }
    }

    /// Envoie un scan au Mac, si l'envoi est actif.
    func send(payload: String, symbology: Symbology) {
        guard isSending, let connection else { return }
        do {
            let line = try MacLinkMessage(payload: payload, symbology: symbology.rawValue).encodedLine()
            connection.send(content: line, completion: .contentProcessed { error in
                if let error { Logger.general.error("Scan non envoyé au Mac : \(error.localizedDescription)") }
            })
        } catch {
            Logger.general.error("Scan non encodé : \(error.localizedDescription)")
        }
    }
}
