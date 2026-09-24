import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Clavier adapté au champ (sans effet sur Mac).
enum FieldKeyboard {
    case url, email, phone, number, decimal, numbersAndPunctuation
}
