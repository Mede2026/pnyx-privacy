import SwiftUI

struct SMSForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Numéro de téléphone", text: $model.smsNumber)
            .fieldKeyboard(.phone)
            .fieldContent(.phone)
        TextField("Message", text: $model.smsMessage, axis: .vertical)
            .lineLimit(3...10)
    }
}
