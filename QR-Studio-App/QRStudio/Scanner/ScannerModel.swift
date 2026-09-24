import CoreLocation
import Foundation
import Observation
import QRCore
import SwiftUI

/// État du scanner. La session caméra ne tourne que si `shouldScan` est vrai :
/// jamais derrière une feuille, jamais en arrière-plan, jamais hors de l'onglet.
@MainActor
@Observable
final class ScannerModel {
    enum Phase: Equatable {
        case idle
        case sweeping
        case presenting
    }

    // Réglages de timing de l'animation (voir SweepOverlay).
    static let sweepDuration: Duration = .milliseconds(600)
    static let confirmDuration: Duration = .milliseconds(150)
    static let duplicateWindow: TimeInterval = 3

    var mode: ScanMode = .single {
        didSet { if mode != oldValue { resetForModeChange() } }
    }
    private(set) var phase: Phase = .idle
    private(set) var sweep: Sweep?
    private(set) var sweepSucceeded = false
    /// Quadrilatère lissé du code suivi, mis à jour à chaque image.
    private(set) var trackedQuad: Quad?

    var resultEntry: CodeEntry?
    var choices: [DetectedBarcode] = []
    var banner: AutoOpenBannerState?
    /// QR d'appairage d'un Mac, en attente de confirmation (jamais enregistré dans l'historique).
    var pairingCandidate: MacLinkPairing?
    let batch = BatchSession()
    private(set) var lastEntry: CodeEntry?

    var isTabActive = true
    var isAppActive = true
    var isTorchOn = false
    /// Intensité de la torche, de 0,1 à 1.
    var torchLevel: Float = 1
    var zoomFactor: Double = 1

    /// Mode lot, ou scan continu en mode simple : aucune feuille, les résultats s'empilent dans la liste.
    var stacksResults: Bool {
        mode == .batch || settings?.continuousScan == true
    }

    /// Condition unique de fonctionnement de la caméra.
    var shouldScan: Bool {
        isTabActive && isAppActive && phase != .presenting && resultEntry == nil
            && choices.isEmpty && banner == nil && pairingCandidate == nil
    }

    @ObservationIgnored private var lastHandled: [String: Date] = [:]
    @ObservationIgnored private var sweepTask: Task<Void, Never>?
    @ObservationIgnored private var visibleCodes: [LiveCode] = []

    @ObservationIgnored var store: EntryStore?
    @ObservationIgnored var feedback: Feedback?
    @ObservationIgnored var settings: AppSettings?
    /// Position au moment du scan, fournie seulement si l'utilisateur l'a activée.
    @ObservationIgnored var locationProvider: (() -> CLLocation?)?
    /// Décide de l'ouverture automatique et l'exécute.
    @ObservationIgnored var autoOpener: AutoOpener?
    /// Appelé après chaque scan enregistré (envoi vers le Mac appairé).
    @ObservationIgnored var onScan: ((String, Symbology) -> Void)?

    // MARK: - Entrées du flux caméra

    /// Appelé à chaque image avec tous les codes visibles.
    func camera(didSee codes: [LiveCode]) {
        visibleCodes = codes
        guard !codes.isEmpty else { return }
        switch phase {
        case .idle:
            if let target = codes.first(where: { !isRecentDuplicate($0.payload) }) {
                begin(with: target, all: codes)
            }
        case .sweeping:
            // Seul le code en cours est suivi ; s'il sort du champ, le balayage finit à sa dernière position.
            if let same = codes.first(where: { $0.payload == currentPayload }) { track(same) }
        case .presenting:
            break
        }
    }

    /// Scan depuis une image fixe (photothèque, presse-papier) : pas de position à l'écran.
    func imageDidDecode(_ codes: [DetectedBarcode]) {
        guard !codes.isEmpty else { return }
        if let code = codes.first, let pairing = MacLinkPairing(qrPayload: code.payload) {
            pairingCandidate = pairing
            return
        }
        if codes.count > 1 {
            choices = codes
        } else if let code = codes.first {
            present(record(payload: code.payload, symbology: code.symbology))
        }
    }

    func choose(_ code: DetectedBarcode) {
        choices = []
        present(record(payload: code.payload, symbology: code.symbology))
    }

    func dismissResult() {
        if let payload = resultEntry?.rawValue { lastHandled[payload] = .now }
        if let pairing = pairingCandidate { lastHandled[pairing.qrPayload] = .now }
        pairingCandidate = nil
        resultEntry = nil
        choices = []
        phase = .idle
        sweep = nil
    }

    func reopenLast() {
        guard let lastEntry, lastEntry.deletedAt == nil else { return }
        // Si une présentation précédente a échoué, l'état est remis à zéro avant de rouvrir.
        resultEntry = nil
        Task { [weak self] in
            guard await pause(.milliseconds(50)), let self else { return }
            self.present(lastEntry)
        }
    }

    // MARK: - Séquence de détection

    @ObservationIgnored private var currentPayload: String?
    @ObservationIgnored private var currentSymbology: Symbology = .qr

    private func begin(with code: LiveCode, all: [LiveCode]) {
        lastHandled[code.payload] = .now
        currentPayload = code.payload
        currentSymbology = code.symbology
        trackedQuad = code.quad
        sweep = Sweep(quad: code.quad)
        sweepSucceeded = false
        phase = .sweeping
        feedback?.prepare()

        sweepTask?.cancel()
        sweepTask = Task { [weak self] in
            guard await pause(Self.sweepDuration), let self else { return }
            self.sweepSucceeded = true
            if self.stacksResults {
                self.finishBatchScan()
                return
            }
            self.feedback?.success()
            guard await pause(Self.confirmDuration) else { return }
            self.finishSingleScan()
        }
    }

    /// Stabilité : le balayage reste sur le quadrilatère figé, sauf déplacement réel (> 40 pt).
    private func track(_ code: LiveCode) {
        let smoothed = trackedQuad.map { $0.smoothed(toward: code.quad) } ?? code.quad
        trackedQuad = smoothed
        if let frozen = sweep?.quad, frozen.maxCornerDistance(to: smoothed) > 40 {
            sweep?.quad = smoothed
        }
    }

    private func finishSingleScan() {
        guard let payload = currentPayload else { return }
        if let pairing = MacLinkPairing(qrPayload: payload) {
            phase = .presenting
            pairingCandidate = pairing
            return
        }
        let distinct = Set(visibleCodes.map(\.payload))
        if distinct.count > 1 {
            // Plusieurs codes dans le champ : impossible de deviner, on affiche la liste.
            choices = visibleCodes.map { DetectedBarcode(payload: $0.payload, symbology: $0.symbology) }
            phase = .presenting
            return
        }
        let entry = record(payload: payload, symbology: currentSymbology)
        phase = .presenting
        guard let autoOpener else {
            present(entry)
            return
        }
        let mode = mode
        Task { [weak self] in
            let autoOpen = await autoOpener.shouldAutoOpen(entry, mode: mode)
            guard let self else { return }
            if autoOpen, let banner = autoOpener.banner(for: entry) {
                self.banner = banner
                self.lastEntry = entry
            } else {
                self.present(entry)
            }
        }
    }

    private func finishBatchScan() {
        guard let payload = currentPayload, let settings else { return }
        let isDuplicate = batch.contains(payload)
        if isDuplicate && !settings.countsDuplicatesSeparately {
            batch.increment(payload, store: store)
        } else {
            let entry = record(payload: payload, symbology: currentSymbology)
            batch.append(entry)
        }
        feedback?.batchAdded(isDuplicate: isDuplicate)
        Announcer.say(isDuplicate
            ? String(localized: "Doublon, \(batch.count) codes")
            : String(localized: "Ajouté, \(batch.count) codes"))
        Task { [weak self] in
            guard await pause(.milliseconds(250)), let self, self.stacksResults else { return }
            self.sweep = nil
            self.phase = .idle
        }
    }

    private func record(payload: String, symbology: Symbology) -> CodeEntry {
        let location = locationProvider?()
        let entry: CodeEntry
        if let store {
            entry = store.recordScan(payload: payload, symbology: symbology, location: location)
        } else {
            let parsed = ScannedContentParser.parse(payload, symbology: symbology)
            entry = CodeEntry(rawValue: payload, symbology: symbology, contentType: parsed.contentType, origin: .scanned)
        }
        lastEntry = entry
        onScan?(payload, symbology)
        return entry
    }

    private func present(_ entry: CodeEntry) {
        phase = .presenting
        resultEntry = entry
    }

    /// Bannière annulée : on montre la feuille pour que l'utilisateur choisisse.
    func cancelAutoOpen() {
        guard let entry = banner?.entry else { banner = nil; return }
        banner = nil
        present(entry)
    }

    func autoOpenCompleted() {
        if let payload = banner?.entry.rawValue { lastHandled[payload] = .now }
        banner = nil
        phase = .idle
        sweep = nil
    }

    private func isRecentDuplicate(_ payload: String) -> Bool {
        guard let date = lastHandled[payload] else { return false }
        return Date.now.timeIntervalSince(date) < Self.duplicateWindow
    }

    private func resetForModeChange() {
        sweepTask?.cancel()
        sweep = nil
        trackedQuad = nil
        phase = .idle
        if isTorchOn {
            isTorchOn = false
            TorchController.set(false)
        }
    }
}
