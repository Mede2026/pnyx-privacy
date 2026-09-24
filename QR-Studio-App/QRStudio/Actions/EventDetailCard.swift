import MapKit
import QRCore
import SwiftUI

/// Événement : dates dans le fuseau local et durée calculée.
struct EventDetailCard: View {
    let event: CalendarEvent

    var body: some View {
        CardSection {
            Text(event.title.isEmpty ? String(localized: "Événement") : event.title).font(.title2.bold())
            if let start = event.start {
                LabeledContent("Début", value: start.formatted(date: .complete, time: event.isAllDay ? .omitted : .shortened))
            }
            if let end = event.end {
                LabeledContent("Fin", value: end.formatted(date: .complete, time: event.isAllDay ? .omitted : .shortened))
            }
            if let duration = event.duration {
                LabeledContent("Durée", value: Duration.seconds(duration).formatted(.units(allowed: [.days, .hours, .minutes], width: .wide)))
            }
            if !event.location.isEmpty { LabeledContent("Localisation", value: event.location) }
            if !event.notes.isEmpty {
                Text(event.notes).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
