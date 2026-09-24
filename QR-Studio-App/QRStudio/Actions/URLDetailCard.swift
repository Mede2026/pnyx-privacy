import MapKit
import QRCore
import SwiftUI

/// Lien : domaine isolé en gras, chemin en gris, paramètres listés séparément.
struct URLDetailCard: View {
    let url: URL
    let actions: ActionHandler

    var body: some View {
        let report = URLSafety.analyze(url)
        CardSection {
            Text(report.displayHost)
                .font(.title2.bold())
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .textSelection(.enabled)
            if !report.path.isEmpty, report.path != "/" {
                Text(report.path)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            if !report.queryItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(report.queryItems.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name).font(.caption.monospaced().bold())
                            Text(item.value ?? "").font(.caption.monospaced()).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
            }
            LinkPreviewRow(url: url)
            ForEach(report.warnings, id: \.self) { warning in
                Label(warningText(warning), systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func warningText(_ warning: URLSafetyReport.Warning) -> String {
        switch warning {
        case .notEncrypted: String(localized: "Ce lien n’est pas chiffré (http).")
        case .deceptiveCharacters(let host): String(localized: "Caractères trompeurs : la vraie adresse est \(host).")
        case .shortener: String(localized: "Lien raccourci : la vraie destination est cachée.")
        case .ipAddress: String(localized: "Ce lien utilise une adresse IP au lieu d’un nom de domaine.")
        case .embeddedCredentials: String(localized: "L’adresse cache du texte avant le vrai domaine.")
        case .payment: String(localized: "Lien de paiement : vérifiez le destinataire avant de payer.")
        }
    }
}
