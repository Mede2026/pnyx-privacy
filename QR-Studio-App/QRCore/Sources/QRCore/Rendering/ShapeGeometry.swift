import CoreGraphics
import Foundation

/// Construction des chemins, en coordonnées de modules (1 unité = 1 module).
enum ShapeGeometry {
    /// Ajoute un module de données à la position (x, y).
    /// `neighbors` renvoie vrai si le module voisin (dx, dy) est noir, pour la forme à coins liés.
    static func addModule(
        _ shape: ModuleShape,
        to path: CGMutablePath,
        x: Int,
        y: Int,
        neighbors: (Int, Int) -> Bool
    ) {
        let rect = CGRect(x: CGFloat(x), y: CGFloat(y), width: 1, height: 1)
        switch shape {
        case .square:
            path.addRect(rect)
        case .rounded:
            path.addRoundedRect(in: rect.insetBy(dx: 0.05, dy: 0.05), cornerWidth: 0.3, cornerHeight: 0.3)
        case .circle:
            path.addEllipse(in: rect.insetBy(dx: 0.06, dy: 0.06))
        case .diamond:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
        case .connected:
            let top = neighbors(0, -1)
            let bottom = neighbors(0, 1)
            let left = neighbors(-1, 0)
            let right = neighbors(1, 0)
            addCornerRect(
                to: path,
                rect: rect,
                radius: 0.5,
                topLeft: !(top || left),
                topRight: !(top || right),
                bottomRight: !(bottom || right),
                bottomLeft: !(bottom || left)
            )
        }
    }

    /// Rectangle dont chaque coin est arrondi ou non, indépendamment.
    static func addCornerRect(
        to path: CGMutablePath,
        rect: CGRect,
        radius: CGFloat,
        topLeft: Bool,
        topRight: Bool,
        bottomRight: Bool,
        bottomLeft: Bool
    ) {
        let r = min(radius, rect.width / 2, rect.height / 2)
        path.move(to: CGPoint(x: rect.minX + (topLeft ? r : 0), y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - (topRight ? r : 0), y: rect.minY))
        if topRight {
            path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                        tangent2End: CGPoint(x: rect.maxX, y: rect.minY + r), radius: r)
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - (bottomRight ? r : 0)))
        if bottomRight {
            path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                        tangent2End: CGPoint(x: rect.maxX - r, y: rect.maxY), radius: r)
        }
        path.addLine(to: CGPoint(x: rect.minX + (bottomLeft ? r : 0), y: rect.maxY))
        if bottomLeft {
            path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                        tangent2End: CGPoint(x: rect.minX, y: rect.maxY - r), radius: r)
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + (topLeft ? r : 0)))
        if topLeft {
            path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                        tangent2End: CGPoint(x: rect.minX + r, y: rect.minY), radius: r)
        }
        path.closeSubpath()
    }

    /// Anneau extérieur d'un œil : 7 × 7 modules, épaisseur exacte d'un module.
    /// Le trou central est tracé en sens inverse pour être vidé par la règle pair-impair.
    static func addEyeFrame(_ shape: EyeFrameShape, to path: CGMutablePath, origin: CGPoint) {
        let outer = CGRect(origin: origin, size: CGSize(width: 7, height: 7))
        let inner = outer.insetBy(dx: 1, dy: 1)
        switch shape {
        case .square:
            path.addRect(outer)
            path.addRect(inner)
        case .rounded:
            path.addRoundedRect(in: outer, cornerWidth: 2, cornerHeight: 2)
            path.addRoundedRect(in: inner, cornerWidth: 1.2, cornerHeight: 1.2)
        case .circle:
            path.addEllipse(in: outer)
            path.addEllipse(in: inner)
        }
    }

    /// Centre d'un œil : 3 × 3 modules, à 2 modules du bord extérieur.
    static func addEyeBall(_ shape: EyeBallShape, to path: CGMutablePath, origin: CGPoint) {
        let rect = CGRect(x: origin.x + 2, y: origin.y + 2, width: 3, height: 3)
        switch shape {
        case .square:
            path.addRect(rect)
        case .rounded:
            path.addRoundedRect(in: rect, cornerWidth: 0.9, cornerHeight: 0.9)
        case .circle:
            path.addEllipse(in: rect)
        case .diamond:
            let grown = rect.insetBy(dx: -0.25, dy: -0.25)
            path.move(to: CGPoint(x: grown.midX, y: grown.minY))
            path.addLine(to: CGPoint(x: grown.maxX, y: grown.midY))
            path.addLine(to: CGPoint(x: grown.midX, y: grown.maxY))
            path.addLine(to: CGPoint(x: grown.minX, y: grown.midY))
            path.closeSubpath()
        }
    }
}
