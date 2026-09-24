import Foundation
import SwiftData
import Testing
@testable import QRCore

/// Budgets chiffrés de la spécification, mesurés en build optimisé :
/// QR_STUDIO_PERF=1 swift test -c release -Xswiftc -enable-testing --filter PerformanceBudget
/// Les mesures de lancement, de défilement et de batterie restent à faire dans Instruments, sur appareil.
@Suite("Budgets de performance", .enabled(if: ProcessInfo.processInfo.environment["QR_STUDIO_PERF"] == "1"))
struct PerformanceBudgetTests {
    /// Médiane de plusieurs essais, en millisecondes.
    private func median(runs: Int = 15, _ work: () throws -> Void) rethrows -> Double {
        var samples: [Double] = []
        for _ in 0..<runs {
            let start = ContinuousClock.now
            try work()
            let elapsed = ContinuousClock.now - start
            samples.append(Double(elapsed.components.attoseconds) / 1e15 + Double(elapsed.components.seconds) * 1000)
        }
        return samples.sorted()[samples.count / 2]
    }

    private var styled: StyleConfig {
        var style = StylePresets.all.first { $0.id == "liquid" }?.config ?? StyleConfig()
        style.gradientKind = .linear
        style.gradientEnd = RGBAColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 1)
        return style
    }

    /// Aperçu en direct d'un QR stylisé : moins de 16 ms, sinon l'édition du style saccade.
    @Test func styledPreviewUnder16ms() async throws {
        let request = RenderRequest(payload: "https://exemple.com/menu?table=12&langue=fr", symbology: .qr, style: styled)
        _ = try await CodeRenderer.shared.drawing(for: request)
        let renderer = CodeRenderer.shared
        var drawing: CodeDrawing?
        let milliseconds = try await measureAsync { drawing = try await renderer.drawing(for: request) }
        let image = try median { _ = try drawing?.makeImage(width: 600) }
        Attachment.record("Aperçu stylisé : dessin \(Self.format(milliseconds)) ms + image \(Self.format(image)) ms", named: "mesure.txt")
        #expect(milliseconds + image < 16)
    }

    /// Export PNG 2048 px : moins de 500 ms.
    @Test func png2048Under500ms() async throws {
        let request = RenderRequest(payload: "WIFI:T:WPA;S:Maison;P:motdepasse;;", symbology: .qr, style: styled)
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        let milliseconds = try median(runs: 5) { _ = try drawing.pngData(width: 2048) }
        Attachment.record("PNG 2048 px : \(Self.format(milliseconds)) ms", named: "mesure.txt")
        #expect(milliseconds < 500)
    }

    /// Historique de 2000 entrées : une page de 50 avec recherche et filtres, exécutée en base.
    @MainActor
    @Test func historyPageWith2000Entries() throws {
        let container = try AppModelContainer.make(cloudSync: false, inMemory: true)
        let context = container.mainContext
        let types: [ContentType] = [.url, .text, .wifi, .product, .contact]
        for index in 0..<2000 {
            let type = types[index % types.count]
            let entry = CodeEntry(rawValue: "code \(index) \(type.rawValue)", symbology: .qr, contentType: type,
                                  origin: index.isMultiple(of: 3) ? .generated : .scanned)
            entry.createdAt = Date.now.addingTimeInterval(Double(-index) * 3600)
            entry.note = index.isMultiple(of: 7) ? "chalet" : ""
            context.insert(entry)
        }
        try context.save()
        var criteria = HistoryPredicate.Criteria(origins: CodeEntry.Origin.allCases.map(\.rawValue),
                                                 contentTypes: ContentType.allCases.map(\.rawValue),
                                                 symbologies: Symbology.allCases.map(\.rawValue))
        criteria.text = "chalet"
        var descriptor = FetchDescriptor(predicate: HistoryPredicate.make(criteria),
                                         sortBy: [SortDescriptor(\CodeEntry.createdAt, order: .reverse)])
        descriptor.fetchLimit = 50
        descriptor.fetchOffset = 100
        let milliseconds = try median { _ = try context.fetch(descriptor) }
        Attachment.record("Page de 50 parmi 2000 (recherche) : \(Self.format(milliseconds)) ms", named: "mesure.txt")
        #expect(milliseconds < 16)
    }

    /// Safe Browsing : décodage Rice d'une liste de la taille réelle (2,4 millions de préfixes).
    @Test func riceDecodingOfARealSizedList() throws {
        var values: [UInt32] = (0..<2_400_000).map { _ in UInt32.random(in: 0...UInt32.max) }
        values.sort()
        let k = 11
        var bits: [Bool] = []
        bits.reserveCapacity(values.count * (k + 3))
        for (previous, value) in zip(values, values.dropFirst()) {
            let delta = value &- previous
            bits += Array(repeating: true, count: Int(delta >> UInt32(k))) + [false]
            bits += (0..<k).map { (delta >> UInt32($0)) & 1 == 1 }
        }
        var data = Data(count: (bits.count + 7) / 8)
        for (index, bit) in bits.enumerated() where bit { data[index / 8] |= 1 << UInt8(index % 8) }
        let milliseconds = try median(runs: 3) {
            let decoded = try RiceDeltaDecoder.decode(firstValue: values[0], riceParameter: k,
                                                      entriesCount: values.count - 1, encodedData: data)
            #expect(decoded.count == values.count)
        }
        Attachment.record("Décodage Rice de 2,4 M préfixes : \(Self.format(milliseconds)) ms", named: "mesure.txt")
        #expect(milliseconds < 2000)
    }

    /// Requête Visual Intelligence : décodage Vision d'une image puis recherche dans l'index, moins de 300 ms.
    @Test func visualLookupUnder300ms() async throws {
        let payloads = (0..<2000).map { "https://exemple.com/code/\($0)" }
        let index = Dictionary(uniqueKeysWithValues: payloads.map { ($0, UUID()) })
        let target = payloads[1234]
        let image = try await CodeRenderer.shared.drawing(for: RenderRequest(payload: target, symbology: .qr)).pngData(width: 1200)
        _ = try ImageBarcodeDecoder.decode(imageData: image)
        let milliseconds = try median(runs: 7) {
            let codes = try ImageBarcodeDecoder.decode(imageData: image)
            let matches = codes.compactMap { index[$0.payload] }
            #expect(matches.count == 1)
        }
        Attachment.record("Visual Intelligence (Vision + index de 2000) : \(Self.format(milliseconds)) ms", named: "mesure.txt")
        #expect(milliseconds < 300)
    }

    private func measureAsync(_ work: () async throws -> Void) async throws -> Double {
        var samples: [Double] = []
        for _ in 0..<15 {
            let start = ContinuousClock.now
            try await work()
            let elapsed = ContinuousClock.now - start
            samples.append(Double(elapsed.components.attoseconds) / 1e15 + Double(elapsed.components.seconds) * 1000)
        }
        return samples.sorted()[samples.count / 2]
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
