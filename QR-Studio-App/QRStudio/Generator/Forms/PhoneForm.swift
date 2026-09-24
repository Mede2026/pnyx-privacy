import SwiftUI

struct PhoneForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Numéro de téléphone", text: $model.phone)
            .fieldKeyboard(.phone)
            .fieldContent(.phone)
    }
}
