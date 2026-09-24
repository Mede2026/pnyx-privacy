import QRCore
import SwiftUI

struct SocialForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        Picker("Plateforme", selection: $model.socialPlatform) {
            ForEach(SocialPlatform.allCases) { Text($0.displayName).tag($0) }
        }
        TextField("Nom d’utilisateur", text: $model.socialUsername)
            .noAutocapitalization()
            .autocorrectionDisabled()
    }
}
