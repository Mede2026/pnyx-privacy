import CryptoKit
import Foundation
import OSLog
import QRCore
import SwiftUI

/// Vignettes de 120 px, générées une fois puis mises en cache : NSCache en mémoire,
/// fichiers PNG dans Caches sur disque. Jamais dans SwiftData, qui les synchroniserait pour rien.
/// La clé combine l'UUID de l'entrée et l'empreinte du style : un changement de style
/// invalide la vignette sans code de nettoyage.
actor ThumbnailCache {
    static let shared = ThumbnailCache()
    static let pixelSize = 120

    private let memory = NSCache<NSString, PlatformImage>()
    private let directory: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("Thumbnails", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            Logger.rendering.error("Dossier des vignettes non créé : \(error.localizedDescription)")
        }
        memory.countLimit = 400
    }

    nonisolated static func key(id: UUID, request: RenderRequest) -> String {
        let content = "\(request.payload)|\(request.symbology.rawValue)|\(request.style.fingerprint)"
        let digest = SHA256.hash(data: Data(content.utf8)).prefix(6).map { String(format: "%02x", $0) }.joined()
        return "\(id.uuidString)-\(digest)"
    }

    func image(id: UUID, request: RenderRequest) async -> PlatformImage? {
        let key = Self.key(id: id, request: request)
        if let cached = memory.object(forKey: key as NSString) { return cached }
        let file = directory.appendingPathComponent(key + ".png")
        // Le dossier Caches peut être vidé par le système : on sait toujours régénérer.
        if let data = FileManager.default.contents(atPath: file.path), let image = PlatformImage(data: data) {
            memory.setObject(image, forKey: key as NSString)
            return image
        }
        guard request.symbology.isGeneratable else { return nil }
        do {
            let drawing = try await CodeRenderer.shared.drawing(for: request)
            let data = try drawing.pngData(width: Self.pixelSize)
            try data.write(to: file, options: .atomic)
            guard let image = PlatformImage(data: data) else { return nil }
            memory.setObject(image, forKey: key as NSString)
            return image
        } catch {
            Logger.rendering.debug("Vignette impossible : \(error.localizedDescription)")
            return nil
        }
    }

    /// Lecture seule, sans rendu : pour Visual Intelligence, qui doit répondre vite.
    func cachedImageData(id: UUID, request: RenderRequest) -> Data? {
        let key = Self.key(id: id, request: request)
        return FileManager.default.contents(atPath: directory.appendingPathComponent(key + ".png").path)
    }
}

extension CodeEntry {
    /// Demande de rendu pour la vignette : le style de l'entrée, ou le style par défaut.
    var renderRequest: RenderRequest {
        var style = style?.config ?? StyleConfig()
        style.frameEnabled = false
        let symbology = symbologyKind.isGeneratable ? symbologyKind : .qr
        return RenderRequest(payload: rawValue, symbology: symbology, style: style)
    }
}
