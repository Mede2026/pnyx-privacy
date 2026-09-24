import QRCore
import SwiftUI

struct SafeBrowsingWarningView: View {
    let warning: SafeBrowsingWarning
    let onOpenAnyway: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var explanation: String?

    static let advisoryURL = URL(string: "https://developers.google.com/safe-browsing/v4/advisory")

    var body: some View {
        let report = URLSafety.analyze(warning.url)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 64))
                    .accessibilityHidden(true)
                Text("Ce site pourrait être dangereux")
                    .font(.largeTitle.bold())
                Text(report.displayHost)
                    .font(.title2.weight(.semibold).monospaced())
                    .textSelection(.enabled)
                Text(warning.threat.reason)
                    .font(.body)
                if let explanation {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Analyse d’Apple Intelligence", systemImage: "apple.intelligence")
                            .font(.caption.weight(.semibold))
                        Text(explanation)
                            .font(.callout)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Avis fourni par Google.")
                        if let url = Self.advisoryURL {
                            Link("En savoir plus", destination: url).underline()
                        }
                    }
                    Text("La protection n’est pas parfaite : elle peut signaler un site sûr ou laisser passer un site dangereux.")
                }
                .font(.footnote)
                .opacity(0.9)

                Button {
                    dismiss()
                } label: {
                    Text("Retour").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.red)
                .controlSize(.large)

                Button("Ouvrir quand même") {
                    onOpenAnyway()
                }
                .font(.footnote)
                .frame(maxWidth: .infinity)
            }
            .padding(28)
            .foregroundStyle(.white)
        }
        .background(Color.red.gradient)
        .task {
            explanation = await OnDeviceIntelligence.explainSuspiciousLink(warning.url, report: report)
        }
        .onAppear { Announcer.say(String(localized: "Attention : ce site pourrait être dangereux.")) }
    }
}
