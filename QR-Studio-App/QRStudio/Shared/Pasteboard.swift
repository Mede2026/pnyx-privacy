import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Presse-papier général.
@MainActor
enum Pasteboard {
    static func copy(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }

    /// Lien ou texte copié, s'il y en a un.
    static func readText() -> String? {
        #if canImport(UIKit)
        UIPasteboard.general.url?.absoluteString ?? UIPasteboard.general.string
        #else
        NSPasteboard.general.string(forType: .URL) ?? NSPasteboard.general.string(forType: .string)
        #endif
    }

    static func copy(image: PlatformImage) {
        #if canImport(UIKit)
        UIPasteboard.general.image = image
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        #endif
    }
}
