import QRCore
import SwiftData
import SwiftUI

/// Création ou modification d'un dossier.
struct FolderEditor: View {
    let folder: Folder?
    var onCreate: ((Folder) -> Void)?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AlertCenter.self) private var alerts
    @State private var name = ""
    @State private var symbolName = "folder"
    @State private var color = Color.accentColor

    static let symbols = ["folder", "creditcard", "wifi", "cart", "house", "briefcase", "ticket", "gift",
                          "book", "fork.knife", "airplane", "car", "heart", "star", "tag", "shippingbox",
                          "person.2", "building.2", "graduationcap", "pawprint"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nom", text: $name)
                ColorPicker("Couleur", selection: $color, supportsOpacity: false)
                Section("Icône") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(Self.symbols, id: \.self) { symbol in
                            Button {
                                symbolName = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(symbol == symbolName ? color.opacity(0.25) : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(verbatim: SymbolNames.name(symbol)))
                            .accessibilityAddTraits(symbol == symbolName ? .isSelected : [])
                        }
                    }
                }
            }
            .navigationTitle(folder == nil ? "Nouveau dossier" : "Modifier le dossier")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard let folder else { return }
                name = folder.name
                symbolName = folder.symbolName
                color = RGBAColor(hex: folder.colorHex)?.color ?? .accentColor
            }
        }
        .sheetHeight(.mediumAndLarge)
        .alertHost()
    }

    private func save() {
        let hex = RGBAColor(color.resolve(in: EnvironmentValues())).hex
        let target = folder ?? Folder(name: name)
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.symbolName = symbolName
        target.colorHex = hex
        if folder == nil { context.insert(target) }
        do {
            try context.save()
            if folder == nil { onCreate?(target) }
            dismiss()
        } catch {
            alerts.show(error)
        }
    }
}
