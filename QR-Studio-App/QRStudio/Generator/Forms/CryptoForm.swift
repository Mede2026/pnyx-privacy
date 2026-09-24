import QRCore
import SwiftUI

struct CryptoForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        Picker("Réseau", selection: $model.cryptoNetwork) {
            ForEach(CryptoNetwork.allCases) { Text($0.displayName).tag($0) }
        }
        TextField("Adresse du portefeuille", text: $model.cryptoAddress)
            .noAutocapitalization()
            .autocorrectionDisabled()
            .font(.body.monospaced())
        TextField("Montant (facultatif)", text: $model.cryptoAmount)
            .fieldKeyboard(.decimal)
    }
}
