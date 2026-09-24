import QRCore
import SwiftData
import SwiftUI

struct OptionalDatePicker: View {
    let title: LocalizedStringKey
    @Binding var date: Date?

    var body: some View {
        Toggle(isOn: Binding(get: { date != nil }, set: { date = $0 ? (date ?? .now) : nil })) {
            Text(title)
        }
        if let value = date {
            DatePicker(title, selection: Binding(get: { value }, set: { date = $0 }), displayedComponents: .date)
                .labelsHidden()
        }
    }
}
