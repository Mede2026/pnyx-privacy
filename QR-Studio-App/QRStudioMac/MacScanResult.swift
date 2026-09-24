import AVFoundation
import AppKit
import QRCore
import SwiftUI

/// Résultat sous l'aperçu : fiche structurée et actions.
struct MacScanResult: View {
    let entry: CodeEntry
    let onContinue: () -> Void
    @Environment(AppServices.self) private var services
    @State private var actions = ActionHandler()

    var body: some View {
        let parsed = ScannedContentParser.parse(entry.rawValue, symbology: entry.symbologyKind)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(parsed.contentType.title, systemImage: parsed.contentType.symbolName)
                        .font(.title3.bold())
                    Spacer()
                    Button("Scanner un autre code", action: onContinue)
                        .keyboardShortcut(.defaultAction)
                }
                ContentDetailCard(parsed: parsed, actions: actions)
                ContentActionsView(parsed: parsed, raw: entry.rawValue, actions: actions, entry: entry)
            }
            .padding(16)
        }
        .frame(maxHeight: 320)
        .background(Color.groupedBackground)
        .onAppear {
            actions.alerts = services.alerts
            Announcer.say("\(parsed.contentType.title). \(entry.summary)")
        }
    }
}
