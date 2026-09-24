import CoreGraphics
import Foundation
import OSLog

/// Ce qu'il faut dessiner : le contenu exact, la symbologie et le style.
public struct RenderRequest: Sendable, Hashable {
    public var payload: String
    public var symbology: Symbology
    public var style: StyleConfig

    public init(payload: String, symbology: Symbology, style: StyleConfig = StyleConfig()) {
        self.payload = payload
        self.symbology = symbology
        self.style = style
    }
}
