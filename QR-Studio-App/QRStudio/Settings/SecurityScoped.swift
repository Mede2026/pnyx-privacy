import QRCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Lecture d'un fichier choisi par l'utilisateur hors du bac à sable.
enum SecurityScoped {
    static func read(_ url: URL) throws -> Data {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        return try Data(contentsOf: url)
    }
}
