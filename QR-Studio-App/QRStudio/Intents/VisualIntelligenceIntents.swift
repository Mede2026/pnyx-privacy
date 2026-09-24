// VisualIntelligence n'existe que sur appareil (absent du SDK du simulateur).
#if canImport(VisualIntelligence)
import AppIntents
import CoreVideo
import Foundation
import QRCore
import SwiftData
import VisualIntelligence

/// Visual Intelligence (iOS 26 et plus) : pointer la caméra vers un code propose les codes déjà enregistrés.
/// Le système abandonne une réponse trop lente : décodage Vision, index par hachage, 5 résultats,
/// aucun réseau, vignettes lues dans le cache sans nouveau rendu.
@available(iOS 26.0, *)
struct CodeVisualQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [CodeEntity] {
        let payloads = Self.payloads(in: input)
        guard !payloads.isEmpty else { return [] }
        return await Self.entities(for: payloads)
    }

    static func payloads(in input: SemanticContentDescriptor) -> [String] {
        guard let buffer = input.pixelBuffer else { return [] }
        do {
            return try buffer.withUnsafeBuffer { pixelBuffer in
                try ImageBarcodeDecoder.decode(pixelBuffer: pixelBuffer).map(\.payload)
            }
        } catch {
            return []
        }
    }

    @MainActor
    static func entities(for payloads: [String]) async -> [CodeEntity] {
        let services = AppServices.shared
        let ids = services.payloadIndex.matches(for: payloads)
        var result: [CodeEntity] = []
        for id in ids {
            guard let entry = services.store.fetchEntry(id: id) else { continue }
            let thumbnail = await ThumbnailCache.shared.cachedImageData(id: entry.id, request: entry.renderRequest)
            result.append(CodeEntity(entry, thumbnail: thumbnail))
        }
        return result
    }
}

#endif
