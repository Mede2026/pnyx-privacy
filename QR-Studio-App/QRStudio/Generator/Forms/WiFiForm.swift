import QRCore
import SwiftUI

struct WiFiForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Nom du réseau (SSID)", text: $model.wifi.ssid)
            .noAutocapitalization()
            .autocorrectionDisabled()
        Picker("Sécurité", selection: $model.wifi.security) {
            Text("WPA / WPA2 / WPA3").tag(WiFiSecurity.wpa)
            Text("WEP").tag(WiFiSecurity.wep)
            Text("Aucun").tag(WiFiSecurity.none)
        }
        if model.wifi.security != .none {
            SecureField("Mot de passe", text: $model.wifi.password)
                .fieldContent(.password)
        }
        Toggle("Réseau masqué", isOn: $model.wifi.hidden)
    }
}
