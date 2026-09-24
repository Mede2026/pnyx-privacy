import QRCore

extension CodeEntry {
    /// Rendu complet (avec cadre et légende) pour l'aperçu et l'export.
    var previewRequest: RenderRequest {
        let symbology = symbologyKind.isGeneratable ? symbologyKind : .qr
        return RenderRequest(payload: rawValue, symbology: symbology, style: style?.config ?? StyleConfig())
    }
}
