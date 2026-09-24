import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Annonce VoiceOver.
@MainActor
enum Announcer {
    static func say(_ text: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: text)
        #else
        if let window = NSApp.keyWindow {
            NSAccessibility.post(element: window, notification: .announcementRequested,
                                 userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.high.rawValue])
        }
        #endif
    }
}
