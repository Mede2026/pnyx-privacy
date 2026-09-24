import QRCore
import SwiftData
import SwiftUI

/// Presets d'usine et presets personnels (enregistrés dans SwiftData, donc synchronisés).
struct PresetStrip: View {
    @Binding var style: StyleConfig
    @Environment(\.modelContext) private var context
    @Environment(AlertCenter.self) private var alerts
    @Query(filter: #Predicate<CodeStyle> { $0.isUserPreset }, sort: \CodeStyle.createdAt, order: .reverse)
    private var userPresets: [CodeStyle]
    @State private var isNaming = false
    @State private var presetName = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button {
                    presetName = ""
                    isNaming = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .frame(width: 64, height: 64)
                            .background(Color.tertiaryFill, in: RoundedRectangle(cornerRadius: 12))
                        Text("Enregistrer").font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Enregistrer comme préréglage"))
                ForEach(userPresets) { preset in
                    tile(name: preset.presetName, config: preset.config)
                        .contextMenu {
                            Button("Supprimer", systemImage: "trash", role: .destructive) {
                                context.delete(preset)
                                save()
                            }
                        }
                }
                ForEach(StylePresets.all) { preset in
                    tile(name: preset.name, config: preset.config)
                }
            }
            .padding(12)
        }
        .alert("Nommez ce préréglage", isPresented: $isNaming) {
            TextField("Nom", text: $presetName)
            Button("Annuler", role: .cancel) {}
            Button("Enregistrer") {
                let preset = CodeStyle(config: style)
                preset.isUserPreset = true
                preset.presetName = presetName.isEmpty ? String(localized: "Mon style") : presetName
                context.insert(preset)
                save()
            }
        }
    }

    private func tile(name: String, config: StyleConfig) -> some View {
        Button {
            // Un preset n'efface pas le logo choisi.
            var applied = config
            applied.logoPNG = config.logoPNG ?? style.logoPNG
            applied.logoSymbolName = config.logoSymbolName ?? style.logoSymbolName
            style = applied
        } label: {
            VStack(spacing: 6) {
                CodePreview(request: RenderRequest(payload: "QR Studio", symbology: .qr, style: config), pixelWidth: 160)
                    .frame(width: 64, height: 64)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                Text(name)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(maxWidth: 72)
            }
        }
        .buttonStyle(.plain)
    }

    private func save() {
        do {
            try context.save()
        } catch {
            alerts.show(error)
        }
    }
}
