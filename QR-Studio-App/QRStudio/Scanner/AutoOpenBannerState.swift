import Foundation
import QRCore

/// Bannière de 1,5 s affichée avant une ouverture automatique, avec un bouton Annuler.
struct AutoOpenBannerState: Identifiable {
    let id = UUID()
    let entry: CodeEntry
    let title: String
    let detail: String
    let symbolName: String
    let action: PrimaryAction
}
