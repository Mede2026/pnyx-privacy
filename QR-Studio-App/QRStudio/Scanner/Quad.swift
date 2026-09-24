import CoreGraphics
import QRCore

/// Quadrilatère d'un code détecté, en coordonnées de la vue.
/// Il contient déjà la rotation et la perspective : aucun calcul 3D n'est nécessaire.
struct Quad: Equatable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint

    var corners: [CGPoint] { [topLeft, topRight, bottomRight, bottomLeft] }

    var center: CGPoint {
        CGPoint(x: corners.map(\.x).reduce(0, +) / 4, y: corners.map(\.y).reduce(0, +) / 4)
    }

    var path: CGPath {
        let path = CGMutablePath()
        path.addLines(between: corners)
        path.closeSubpath()
        return path
    }

    /// Filtre passe-bas : lissé = lissé × 0,7 + nouveau × 0,3.
    func smoothed(toward new: Quad, factor: CGFloat = 0.3) -> Quad {
        func mix(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            CGPoint(x: a.x * (1 - factor) + b.x * factor, y: a.y * (1 - factor) + b.y * factor)
        }
        return Quad(topLeft: mix(topLeft, new.topLeft), topRight: mix(topRight, new.topRight),
                    bottomRight: mix(bottomRight, new.bottomRight), bottomLeft: mix(bottomLeft, new.bottomLeft))
    }

    /// Plus grand déplacement d'un coin, pour décider d'un ré-ancrage.
    func maxCornerDistance(to other: Quad) -> CGFloat {
        zip(corners, other.corners).map { hypot($0.x - $1.x, $0.y - $1.y) }.max() ?? 0
    }

    /// Carré centré dans un rectangle, utilisé pour les images fixes sans position connue.
    static func centered(in rect: CGRect, side: CGFloat) -> Quad {
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        return Quad(topLeft: origin,
                    topRight: CGPoint(x: origin.x + side, y: origin.y),
                    bottomRight: CGPoint(x: origin.x + side, y: origin.y + side),
                    bottomLeft: CGPoint(x: origin.x, y: origin.y + side))
    }
}
