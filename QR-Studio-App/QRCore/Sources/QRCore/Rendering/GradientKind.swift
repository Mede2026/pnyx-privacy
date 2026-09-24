import CryptoKit
import Foundation

public enum GradientKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case none, linear, radial
    public var id: String { rawValue }
}
