import Foundation

public struct SMSMessage: Sendable, Hashable {
    public init(number: String, body: String) {
        self.number = number
        self.body = body
    }

    public var number: String
    public var body: String
}
