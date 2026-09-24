import Foundation

/// Symbologies reconnues au scan et, pour une partie d'entre elles, générables.
public enum Symbology: String, CaseIterable, Codable, Sendable, Identifiable {
    case qr
    case microQR
    case aztec
    case pdf417
    case microPDF417
    case dataMatrix
    case gs1DataBar
    case gs1DataBarExpanded
    case gs1DataBarLimited
    case ean8
    case ean13
    case upcA
    case upcE
    case code39
    case code93
    case code128
    case itf14
    case i2of5
    case codabar
    case msiPlessey
    case unknown

    public var id: String { rawValue }

    public init(storedValue: String) {
        self = Symbology(rawValue: storedValue) ?? .unknown
    }

    /// Noms techniques : identiques dans toutes les langues.
    public var displayName: String {
        switch self {
        case .qr: "QR"
        case .microQR: "Micro QR"
        case .aztec: "Aztec"
        case .pdf417: "PDF417"
        case .microPDF417: "MicroPDF417"
        case .dataMatrix: "Data Matrix"
        case .gs1DataBar: "GS1 DataBar"
        case .gs1DataBarExpanded: "GS1 DataBar Expanded"
        case .gs1DataBarLimited: "GS1 DataBar Limited"
        case .ean8: "EAN-8"
        case .ean13: "EAN-13"
        case .upcA: "UPC-A"
        case .upcE: "UPC-E"
        case .code39: "Code 39"
        case .code93: "Code 93"
        case .code128: "Code 128"
        case .itf14: "ITF-14"
        case .i2of5: "2 parmi 5 entrelacé"
        case .codabar: "Codabar"
        case .msiPlessey: "MSI Plessey"
        case .unknown: "?"
        }
    }

    public var isTwoDimensional: Bool {
        switch self {
        case .qr, .microQR, .aztec, .pdf417, .microPDF417, .dataMatrix: true
        default: false
        }
    }

    /// Codes produits (GTIN) : EAN, UPC et ITF-14.
    public var isProductCode: Bool {
        switch self {
        case .ean8, .ean13, .upcA, .upcE, .itf14: true
        default: false
        }
    }

    /// Symbologies que l'app sait dessiner.
    public var isGeneratable: Bool {
        switch self {
        case .qr, .aztec, .pdf417, .code128, .ean13, .ean8, .upcA, .code39, .itf14, .i2of5: true
        default: false
        }
    }

    /// Vrai si le style complet (formes, yeux, logo) s'applique ; sinon seules les couleurs comptent.
    public var supportsFullStyling: Bool { self == .qr }
}
