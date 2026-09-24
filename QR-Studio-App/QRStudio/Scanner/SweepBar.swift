import QRCore
import SwiftUI

/// Barre qui épouse le code : ses extrémités glissent le long des côtés latéraux du quadrilatère.
/// L'interpolation bilinéaire donne l'inclinaison, la perspective et l'axe réel du code.
struct SweepBar: View {
    let quad: Quad
    let progress: Double

    var body: some View {
        Canvas { context, _ in
            context.addFilter(.blur(radius: 3))
            // Traînée : quelques copies légèrement en retard, de plus en plus transparentes.
            let trail: [(offset: Double, opacity: Double)] = [(0.09, 0.15), (0.06, 0.3), (0.03, 0.55), (0, 1)]
            for copy in trail {
                let t = max(0, progress - copy.offset)
                let start = Self.lerp(quad.topLeft, quad.bottomLeft, t)
                let end = Self.lerp(quad.topRight, quad.bottomRight, t)
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                let gradient = Gradient(colors: [.accentColor.opacity(0), .accentColor.opacity(0.9 * copy.opacity),
                                                 .accentColor.opacity(0)])
                context.stroke(path, with: .linearGradient(gradient, startPoint: start, endPoint: end), lineWidth: 4)
            }
        }
    }

    static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
