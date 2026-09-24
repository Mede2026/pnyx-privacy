import Foundation
import OSLog
import QRCore

/// Fichier local des scans reçus de l'iPhone (Application Support), jamais synchronisé.
enum ReceivedScansStore {
    private static var url: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ReceivedScans.json")
    }

    static func load() -> [MacLinkServer.Received] {
        guard let url, let data = FileManager.default.contents(atPath: url.path) else { return [] }
        do {
            return try JSONDecoder().decode([MacLinkServer.Received].self, from: data)
        } catch {
            Logger.general.error("Scans reçus illisibles : \(error.localizedDescription)")
            return []
        }
    }

    static func save(_ received: [MacLinkServer.Received]) {
        guard let url else { return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(received).write(to: url, options: .atomic)
        } catch {
            Logger.general.error("Scans reçus non enregistrés : \(error.localizedDescription)")
        }
    }
}
