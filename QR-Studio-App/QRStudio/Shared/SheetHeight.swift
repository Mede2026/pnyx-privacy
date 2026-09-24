import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Hauteurs de feuille (sans effet sur Mac, où les feuilles s'ajustent au contenu).
enum SheetHeight {
    case medium, mediumAndLarge
}
