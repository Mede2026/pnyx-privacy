import QRCore
import SwiftData
import SwiftUI

/// Éditeur de style : onglets Couleurs, Formes, Logo, Avancé, avec aperçu en direct
/// et indicateur de lisibilité.
struct StyleEditorView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case colors, shapes, logo, advanced
        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .colors: "Couleurs"
            case .shapes: "Formes"
            case .logo: "Logo"
            case .advanced: "Avancé"
            }
        }
    }

    @Binding var style: StyleConfig
    let payload: String
    var onDone: ((StyleConfig) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .colors
    @State private var readability: Readability?

    init(style: Binding<StyleConfig>, payload: String, onDone: ((StyleConfig) -> Void)? = nil) {
        _style = style
        self.payload = payload
        self.onDone = onDone
    }

    var body: some View {
        let request = RenderRequest(payload: payload, symbology: .qr, style: style)
        let check = ReadabilityValidator.checkColors(style)
        Form {
            Section {
                PresetStrip(style: $style)
                    .listRowInsets(EdgeInsets())
            }
            Section {
                Picker("Section", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            switch tab {
            case .colors: ColorsTab(style: $style)
            case .shapes: ShapesTab(style: $style)
            case .logo: LogoTab(style: $style)
            case .advanced: AdvancedTab(style: $style)
            }
        }
        .topBar {
            PinnedPreview(request: request, readability: readability, colorCheck: check)
        }
        .navigationTitle("Style")
        .alertHost()
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("OK") {
                    onDone?(style)
                    dismiss()
                }
                // Garde-fou n° 3 : une combinaison sous 4:1 est bloquée.
                .disabled(check.isContrastTooLow)
            }
        }
        .task(id: request) {
            readability = .checking
            guard await pause(.milliseconds(300)) else { return }
            let result = await ReadabilityValidator.verify(request)
            guard !Task.isCancelled else { return }
            readability = result
        }
    }
}
