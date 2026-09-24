import SwiftUI

struct ProductForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Chiffres (8, 12, 13 ou 14)", text: $model.productCode)
            .fieldKeyboard(.number)
            .font(.body.monospacedDigit())
        Text("EAN-13, EAN-8, UPC-A ou ITF-14 est choisi selon la longueur. Le dernier chiffre est vérifié.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
