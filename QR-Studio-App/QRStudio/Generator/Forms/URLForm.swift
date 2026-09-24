import SwiftUI

struct URLForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Adresse web", text: $model.url, prompt: Text("exemple.com"))
            .fieldKeyboard(.url)
            .fieldContent(.url)
            .noAutocapitalization()
            .autocorrectionDisabled()
        Text("https:// est ajouté automatiquement s’il manque.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
