import SwiftUI

struct TextForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Texte", text: $model.text, axis: .vertical)
            .lineLimit(3...12)
    }
}
