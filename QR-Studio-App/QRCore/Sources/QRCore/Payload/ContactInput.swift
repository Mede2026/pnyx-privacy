import Foundation

public struct ContactInput: Codable, Sendable, Hashable {
    public var firstName = ""
    public var lastName = ""
    public var phone = ""
    public var email = ""
    public var organization = ""
    public var street = ""
    public var city = ""
    public var region = ""
    public var postalCode = ""
    public var country = ""
    public var website = ""
    public init() {}
}
