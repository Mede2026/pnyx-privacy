import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Remplissage automatique du champ (sans effet sur Mac).
enum FieldContent {
    case url, email, phone, password, username, givenName, familyName, organization
    case street, city, state, postalCode, country
}
