import Foundation

public struct EmailMessage: Sendable, Hashable {
    public init(to: String, subject: String, body: String) {
        self.to = to
        self.subject = subject
        self.body = body
    }

    public var to: String
    public var subject: String
    public var body: String
}
