import QRCore
import SwiftData
import SwiftUI

/// Liste du mode lot : monte du bas, avec compteur, quantités et notes modifiables.
struct BatchPanel: View {
    @Environment(ScannerModel.self) private var model
    @Environment(AppServices.self) private var services
    @State private var isChoosingFolder = false
    @State private var isExporting = false
    @State private var isConfirmingClear = false
    @State private var isTranslating = false

    /// Entrées de texte dans une autre langue que celle de l'appareil (jamais un lien, un code produit ou un Wi-Fi).
    private var translatableEntries: [CodeEntry] {
        model.batch.entries.filter { $0.contentKind == .text && ContentActionsView.needsTranslation($0.rawValue) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("\(model.batch.count) scannés", systemImage: "barcode.viewfinder")
                    .font(.headline)
                    .monospacedDigit()
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            if model.batch.isEmpty {
                Text("Pointez la caméra vers les codes-barres les uns après les autres. Ils s’ajoutent ici sans interrompre le scan.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.batch.items) { item in
                            BatchRow(entry: item.entry)
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .frame(maxHeight: 200)
                actionBar
            }
        }
        .glassRoundedRect(cornerRadius: 24)
        .sheet(isPresented: $isChoosingFolder) {
            FolderPickerSheet { folder in
                for entry in model.batch.entries { entry.folder = folder }
                services.store.updated(model.batch.entries)
            }
        }
        .sheet(isPresented: $isTranslating) {
            if #available(iOS 18.0, *) {
                BatchTranslationSheet(entries: translatableEntries)
            }
        }
        .sheet(isPresented: $isExporting) {
            ExportEntriesSheet(entries: model.batch.entries, title: String(localized: "Lot"))
        }
        .confirmationDialog("Tout effacer de la liste ?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button("Tout effacer", role: .destructive) { model.batch.clear() }
        } message: {
            Text("Les codes restent dans votre historique.")
        }
    }

    /// Boutons de fin de lot, toujours visibles.
    private var actionBar: some View {
        HStack(spacing: 8) {
            Button("Dossier", systemImage: "folder.badge.plus") { isChoosingFolder = true }
                .accessibilityLabel(Text("Enregistrer dans un dossier"))
            Button("Exporter", systemImage: "square.and.arrow.up") { isExporting = true }
            if #available(iOS 18.0, *), !translatableEntries.isEmpty {
                Button("Traduire", systemImage: "translate") { isTranslating = true }
            }
            Button("Tout effacer", systemImage: "trash", role: .destructive) { isConfirmingClear = true }
        }
        .font(.footnote.weight(.semibold))
        .labelStyle(.titleAndIcon)
        .glassButtonStyle()
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
