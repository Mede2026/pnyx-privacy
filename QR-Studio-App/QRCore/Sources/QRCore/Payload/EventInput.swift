import Foundation

public struct EventInput: Codable, Sendable, Hashable {
    public var title = ""
    public var location = ""
    public var start = Date()
    public var end = Date().addingTimeInterval(3600)
    public var notes = ""
    public init() {}
}
