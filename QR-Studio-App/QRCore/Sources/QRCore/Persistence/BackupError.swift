import Foundation

public enum BackupError: LocalizedError {
    case unsupportedVersion(Int)
    case unreadable

    public var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            String(format: L("Cette sauvegarde vient d’une version plus récente (format %lld). Mettez d’abord QR Studio à jour."), version)
        case .unreadable:
            L("Ce fichier n’est pas une sauvegarde QR Studio.")
        }
    }
}
