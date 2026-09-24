import SwiftUI

struct EmailForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Destinataire", text: $model.email.recipient)
            .fieldKeyboard(.email)
            .fieldContent(.email)
            .noAutocapitalization()
            .autocorrectionDisabled()
        TextField("Objet", text: $model.email.subject)
        TextField("Message", text: $model.email.body, axis: .vertical)
            .lineLimit(3...10)
    }
}
