import QRCore
import SwiftUI

/// Formes des modules et des yeux. La structure 7 × 7 des yeux est toujours conservée.
struct ShapesTab: View {
    @Binding var style: StyleConfig

    var body: some View {
        Section("Modules") {
            ShapeChooser(selection: $style.moduleShape, options: ModuleShape.allCases) { shape in
                switch shape {
                case .square: ("square.fill", "Carré")
                case .rounded: ("app.fill", "Arrondi")
                case .circle: ("circle.fill", "Cercle")
                case .diamond: ("diamond.fill", "Losange")
                case .connected: ("square.grid.2x2.fill", "Liés")
                }
            }
        }
        Section("Contour des yeux") {
            ShapeChooser(selection: $style.eyeFrameShape, options: EyeFrameShape.allCases) { shape in
                switch shape {
                case .square: ("square", "Carré")
                case .rounded: ("app", "Arrondi")
                case .circle: ("circle", "Cercle")
                }
            }
        }
        Section("Centre des yeux") {
            ShapeChooser(selection: $style.eyeBallShape, options: EyeBallShape.allCases) { shape in
                switch shape {
                case .square: ("square.fill", "Carré")
                case .rounded: ("app.fill", "Arrondi")
                case .circle: ("circle.fill", "Cercle")
                case .diamond: ("diamond.fill", "Losange")
                }
            }
        }
    }
}
