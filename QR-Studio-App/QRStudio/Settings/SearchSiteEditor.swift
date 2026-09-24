import QRCore
import SwiftData
import SwiftUI

struct SearchSiteEditor: View {
    let site: SearchSite?
    var nextOrder = 0
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AlertCenter.self) private var alerts
    @State private var name = ""
    @State private var template = "https://"

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && SearchSite.resolve(template: template, code: "0") != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nom", text: $name)
                TextField("Adresse", text: $template, prompt: Text("https://exemple.com/search?q={code}"))
                    .fieldKeyboard(.url)
                    .noAutocapitalization()
                    .autocorrectionDisabled()
                if !template.contains(SearchSite.codeToken) {
                    Label("L’adresse doit contenir {code}.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle(site == nil ? "Nouveau site" : "Modifier le site")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer", action: save).disabled(!isValid)
                }
            }
            .onAppear {
                if let site {
                    name = site.name
                    template = site.urlTemplate
                }
            }
        }
        .sheetHeight(.medium)
        .alertHost()
    }

    private func save() {
        let target = site ?? SearchSite(name: name, urlTemplate: template, sortOrder: nextOrder)
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.urlTemplate = template.trimmingCharacters(in: .whitespaces)
        if site == nil { context.insert(target) }
        do {
            try context.save()
            dismiss()
        } catch {
            alerts.show(error)
        }
    }
}
