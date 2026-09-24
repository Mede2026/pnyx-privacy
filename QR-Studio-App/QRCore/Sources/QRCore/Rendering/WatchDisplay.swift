import Foundation

/// Règles d'affichage d'un code sur l'Apple Watch, partagées par l'app et la complication.
public enum WatchDisplay {
    /// Au-delà d'environ 300 octets, un QR devient illisible sur un écran de montre.
    public static let maximumBytes = 300

    public static func isTooDense(_ payload: String) -> Bool {
        payload.utf8.count > maximumBytes
    }

    /// Requête de rendu, ou nil si le format ne peut pas être reproduit fidèlement sur la montre.
    /// Un code 2D non dessinable (Aztec, PDF417, Data Matrix) devient un QR au contenu identique ;
    /// un code-barres 1D non dessinable n'est pas remplacé : une caisse attend ce format précis.
    public static func request(payload: String, symbology stored: String, quietZone: Int = 2) -> RenderRequest? {
        let symbology = Symbology(storedValue: stored)
        let drawable: Set<Symbology> = [.qr, .ean13, .ean8, .upcA, .code39, .code128, .itf14, .i2of5]
        let twoDimensional: Set<Symbology> = [.aztec, .pdf417, .microPDF417, .dataMatrix, .microQR, .unknown]
        var style = StyleConfig()
        style.quietZone = quietZone
        if drawable.contains(symbology) {
            return RenderRequest(payload: payload, symbology: symbology, style: style)
        }
        if twoDimensional.contains(symbology) {
            return RenderRequest(payload: payload, symbology: .qr, style: style)
        }
        return nil
    }
}
