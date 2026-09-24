import CoreGraphics
import QRCore

/// Code vu par la caméra : contenu, symbologie et position à l'écran.
struct LiveCode: Equatable {
    var payload: String
    var symbology: Symbology
    var quad: Quad
}
