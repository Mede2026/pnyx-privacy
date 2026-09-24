import Foundation

public struct EmailInput: Codable, Sendable, Hashable {
    public var recipient = ""
    public var subject = ""
    public var body = ""
    public init() {}
}
