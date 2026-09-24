import AppKit
import ApplicationServices
import Foundation
import Network
import Observation
import OSLog
import QRCore

/// Frappe simulée dans l'app active (CGEvent). Exige l'autorisation Accessibilité.
@MainActor
enum KeyboardTyper {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Ouvre la demande d'autorisation du système.
    static func requestTrust() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func type(_ text: String, suffix: MacLinkServer.Suffix) {
        let source = CGEventSource(stateID: .hidSystemState)
        // Par morceaux : certaines apps ignorent les chaînes Unicode trop longues dans un seul événement.
        let characters = Array(text.utf16)
        for start in stride(from: 0, to: characters.count, by: 16) {
            var chunk = Array(characters[start..<min(start + 16, characters.count)])
            for keyDown in [true, false] {
                let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: keyDown)
                event?.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
                event?.post(tap: .cghidEventTap)
            }
        }
        let key: CGKeyCode? = switch suffix {
        case .none: nil
        case .tab: 48
        case .newline: 36
        }
        if let key {
            CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)?.post(tap: .cghidEventTap)
            CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)?.post(tap: .cghidEventTap)
        }
    }
}
