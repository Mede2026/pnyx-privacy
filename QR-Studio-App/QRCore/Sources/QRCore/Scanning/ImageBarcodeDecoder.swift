#if canImport(Vision) && !os(watchOS)
import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import ImageIO
import OSLog
import Vision

/// Décodage de codes dans une image fixe avec VNDetectBarcodesRequest.
/// Sert au scan depuis la photothèque, au presse-papier, à l'extension de partage
/// et à la relecture de vérification des codes générés.
public enum ImageBarcodeDecoder {
    public static func decode(_ image: CGImage, orientation: CGImagePropertyOrientation = .up) throws -> [DetectedBarcode] {
        let request = VNDetectBarcodesRequest()
        #if targetEnvironment(simulator)
        // Le simulateur n'a pas de moteur neuronal : Vision doit calculer sur le processeur.
        useCPU(for: request)
        #endif
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
        } catch {
            // Les erreurs de Vision sont en anglais : on montre un message en français.
            Logger.scanner.error("Vision a échoué : \(error.localizedDescription)")
            throw DecodeError.analysisFailed
        }
        let observations = request.results ?? []
        var seen = Set<String>()
        var result: [DetectedBarcode] = []
        for observation in observations {
            guard let payload = observation.payloadStringValue, !payload.isEmpty else { continue }
            let barcode = DetectedBarcode(
                payload: payload,
                symbology: Symbology(vision: observation.symbology),
                boundingBox: observation.boundingBox
            )
            // Vision peut signaler deux fois le même code (par exemple EAN-13 et UPC-A).
            if seen.insert(barcode.payload).inserted {
                result.append(barcode)
            }
        }
        if result.isEmpty {
            result = coreImageQRCodes(in: image)
        }
        return result
    }

    /// Repli natif pour les QR : le détecteur de Core Image, qui calcule sur le processeur.
    /// Utile quand Vision ne trouve rien (image très petite, simulateur sans moteur neuronal).
    static func coreImageQRCodes(in image: CGImage) -> [DetectedBarcode] {
        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options) else { return [] }
        let features = detector.features(in: CIImage(cgImage: image))
        var seen = Set<String>()
        return features.compactMap { feature in
            guard let qr = feature as? CIQRCodeFeature, let payload = qr.messageString, !payload.isEmpty,
                  seen.insert(payload).inserted else { return nil }
            return DetectedBarcode(payload: payload, symbology: .qr)
        }
    }

    /// Décodage rapide d'une image de caméra (Visual Intelligence) : Vision seul, sans repli.
    public static func decode(pixelBuffer: CVPixelBuffer) throws -> [DetectedBarcode] {
        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            Logger.scanner.error("Vision a échoué : \(error.localizedDescription)")
            throw DecodeError.analysisFailed
        }
        return (request.results ?? []).compactMap { observation in
            guard let payload = observation.payloadStringValue, !payload.isEmpty else { return nil }
            return DetectedBarcode(payload: payload, symbology: Symbology(vision: observation.symbology),
                                   boundingBox: observation.boundingBox)
        }
    }

    /// Décode des données d'image (PNG, JPEG, HEIC…) en respectant leur orientation EXIF.
    public static func decode(imageData: Data) throws -> [DetectedBarcode] {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw DecodeError.unreadableImage
        }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let rawOrientation = properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: rawOrientation) ?? .up
        return try decode(image, orientation: orientation)
    }

    #if targetEnvironment(simulator)
    private static func useCPU(for request: VNRequest) {
        do {
            let devices = try request.supportedComputeStageDevices[.main] ?? []
            if let cpu = devices.first(where: { if case .cpu = $0 { true } else { false } }) {
                request.setComputeDevice(cpu, for: .main)
            }
        } catch {
            Logger.scanner.error("Appareils de calcul Vision illisibles : \(error.localizedDescription)")
        }
    }
    #endif

    public enum DecodeError: LocalizedError {
        case unreadableImage
        case analysisFailed

        public var errorDescription: String? {
            switch self {
            case .unreadableImage: L("Cette image n’a pas pu être ouverte.")
            case .analysisFailed: L("L’analyse de l’image a échoué. Réessayez.")
            }
        }
    }
}

public extension Symbology {
    init(vision: VNBarcodeSymbology) {
        switch vision {
        case .qr: self = .qr
        case .microQR: self = .microQR
        case .aztec: self = .aztec
        case .pdf417: self = .pdf417
        case .microPDF417: self = .microPDF417
        case .dataMatrix: self = .dataMatrix
        case .gs1DataBar: self = .gs1DataBar
        case .gs1DataBarExpanded: self = .gs1DataBarExpanded
        case .gs1DataBarLimited: self = .gs1DataBarLimited
        case .ean8: self = .ean8
        case .ean13: self = .ean13
        case .upce: self = .upcE
        case .code39, .code39Checksum, .code39FullASCII, .code39FullASCIIChecksum: self = .code39
        case .code93, .code93i: self = .code93
        case .code128: self = .code128
        case .itf14: self = .itf14
        case .i2of5, .i2of5Checksum: self = .i2of5
        case .codabar: self = .codabar
        case .msiPlessey: self = .msiPlessey
        default: self = .unknown
        }
    }

    /// Symbologies Vision correspondant à ce type, pour restreindre la détection.
    var visionSymbologies: [VNBarcodeSymbology] {
        switch self {
        case .qr: [.qr]
        case .microQR: [.microQR]
        case .aztec: [.aztec]
        case .pdf417: [.pdf417]
        case .microPDF417: [.microPDF417]
        case .dataMatrix: [.dataMatrix]
        case .gs1DataBar: [.gs1DataBar]
        case .gs1DataBarExpanded: [.gs1DataBarExpanded]
        case .gs1DataBarLimited: [.gs1DataBarLimited]
        case .ean8: [.ean8]
        case .ean13, .upcA: [.ean13]
        case .upcE: [.upce]
        case .code39: [.code39, .code39Checksum, .code39FullASCII, .code39FullASCIIChecksum]
        case .code93: [.code93, .code93i]
        case .code128: [.code128]
        case .itf14: [.itf14]
        case .i2of5: [.i2of5, .i2of5Checksum]
        case .codabar: [.codabar]
        case .msiPlessey: [.msiPlessey]
        case .unknown: []
        }
    }
}
#endif
