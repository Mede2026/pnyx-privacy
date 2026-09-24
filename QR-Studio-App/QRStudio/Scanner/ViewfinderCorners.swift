import QRCore
import SwiftUI

/// Coins de cadrage au centre de l'écran, visibles tant qu'aucun code n'est détecté.
nonisolated struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(rect.width, rect.height) * 0.18
        var path = Path()
        let corners: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: rect.minX, y: rect.minY), 1, 1), (CGPoint(x: rect.maxX, y: rect.minY), -1, 1),
            (CGPoint(x: rect.maxX, y: rect.maxY), -1, -1), (CGPoint(x: rect.minX, y: rect.maxY), 1, -1)
        ]
        for (point, dx, dy) in corners {
            path.move(to: CGPoint(x: point.x + dx * length, y: point.y))
            path.addLine(to: point)
            path.addLine(to: CGPoint(x: point.x, y: point.y + dy * length))
        }
        return path
    }
}
