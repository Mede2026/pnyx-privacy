import QRCore
import SwiftUI

/// Métadonnées : date, heure, lieu, symbologie, type, origine, quantité.
struct DetailMetadata: View {
    let entry: CodeEntry

    var body: some View {
        CardSection {
            LabeledContent("Date", value: entry.createdAt.formatted(date: .long, time: .shortened))
            LabeledContent("Format", value: entry.symbologyKind.displayName)
            LabeledContent("Type", value: entry.contentKind.title)
            LabeledContent("Origine", value: entry.originKind == .scanned ? String(localized: "Scannés") : String(localized: "Créés"))
            if entry.quantity > 1 {
                LabeledContent("Quantité", value: "\(entry.quantity)")
            }
            if let latitude = entry.latitude, let longitude = entry.longitude {
                LabeledContent("Lieu", value: entry.placeName
                               ?? "\(PayloadBuilder.coordinate(latitude)), \(PayloadBuilder.coordinate(longitude))")
            }
            LabeledContent("Caractères", value: "\(entry.rawValue.count)")
        }
    }
}
