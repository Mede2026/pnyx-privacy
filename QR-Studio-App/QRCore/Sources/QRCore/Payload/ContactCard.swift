import Foundation

public struct ContactCard: Sendable, Hashable {
    public init() {}

    public var fullName = ""
    public var firstName = ""
    public var lastName = ""
    public var organization = ""
    public var jobTitle = ""
    public var phones: [String] = []
    public var emails: [String] = []
    public var addresses: [String] = []
    public var urls: [String] = []
    public var note = ""

    public var displayName: String {
        if !fullName.isEmpty { return fullName }
        let composed = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        return composed.isEmpty ? organization : composed
    }
}
