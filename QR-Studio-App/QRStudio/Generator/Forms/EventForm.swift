import SwiftUI

struct EventForm: View {
    @Bindable var model: GeneratorFormModel

    var body: some View {
        TextField("Titre", text: $model.event.title)
        TextField("Localisation", text: $model.event.location)
        DatePicker("Début", selection: $model.event.start)
        DatePicker("Fin", selection: $model.event.end, in: model.event.start...)
        TextField("Notes", text: $model.event.notes, axis: .vertical)
            .lineLimit(2...8)
    }
}
