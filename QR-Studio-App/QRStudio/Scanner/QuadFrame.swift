import QRCore
import SwiftUI

/// Cadre du code : accent pendant le balayage, vert plein à la confirmation.
struct QuadFrame: View {
    let quad: Quad
    let opacity: Double
    let succeeded: Bool

    var body: some View {
        let path = Path(quad.path)
        ZStack {
            path.fill(succeeded ? Color.green.opacity(0.3) : Color.clear)
            path.stroke(succeeded ? Color.green : Color.accentColor,
                        style: StrokeStyle(lineWidth: succeeded ? 4 : 3, lineJoin: .round))
        }
        .opacity(succeeded ? 1 : opacity)
    }
}
