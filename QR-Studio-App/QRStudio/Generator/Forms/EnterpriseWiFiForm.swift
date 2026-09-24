import QRCore
import SwiftUI

struct EnterpriseWiFiForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Nom du réseau (SSID)", text: $model.enterpriseWiFi.ssid)
            .noAutocapitalization()
            .autocorrectionDisabled()
        TextField("Nom d’utilisateur", text: $model.enterpriseWiFi.identity)
            .fieldContent(.username)
            .noAutocapitalization()
            .autocorrectionDisabled()
        SecureField("Mot de passe", text: $model.enterpriseWiFi.password)
            .fieldContent(.password)
        Picker("Méthode EAP", selection: $model.enterpriseWiFi.eap) {
            ForEach(EAPMethod.allCases) { Text($0.rawValue).tag($0) }
        }
    }
}
