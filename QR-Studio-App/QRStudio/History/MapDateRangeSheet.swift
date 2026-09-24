import QRCore
import SwiftUI

/// Plage de dates libre pour la carte des scans.
struct MapDateRangeSheet: View {
    @Binding var start: Date?
    @Binding var end: Date?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    OptionalDatePicker(title: "Du", date: $start)
                    OptionalDatePicker(title: "Au", date: $end)
                } footer: {
                    Text("Sans date de début ni de fin, tous les scans sont affichés.")
                }
            }
            .navigationTitle("Période")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        .sheetHeight(.medium)
    }
}
