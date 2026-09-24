import Foundation

public struct CalendarEvent: Sendable, Hashable {
    public init() {}

    public var title = ""
    public var location = ""
    public var notes = ""
    public var start: Date?
    public var end: Date?
    public var isAllDay = false

    public var duration: TimeInterval? {
        guard let start, let end, end > start else { return nil }
        return end.timeIntervalSince(start)
    }
}
