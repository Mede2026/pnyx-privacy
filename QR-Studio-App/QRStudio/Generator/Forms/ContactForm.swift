import SwiftUI

struct ContactForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Prénom", text: $model.contact.firstName)
            .fieldContent(.givenName)
        TextField("Nom", text: $model.contact.lastName)
            .fieldContent(.familyName)
        TextField("Organisation", text: $model.contact.organization)
            .fieldContent(.organization)
        TextField("Téléphone", text: $model.contact.phone)
            .fieldKeyboard(.phone)
            .fieldContent(.phone)
        TextField("Courriel", text: $model.contact.email)
            .fieldKeyboard(.email)
            .fieldContent(.email)
            .noAutocapitalization()
        TextField("Rue", text: $model.contact.street)
            .fieldContent(.street)
        TextField("Ville", text: $model.contact.city)
            .fieldContent(.city)
        TextField("Province ou État", text: $model.contact.region)
            .fieldContent(.state)
        TextField("Code postal", text: $model.contact.postalCode)
            .fieldContent(.postalCode)
        TextField("Pays", text: $model.contact.country)
            .fieldContent(.country)
        TextField("Site web", text: $model.contact.website)
            .fieldKeyboard(.url)
            .noAutocapitalization()
    }
}
