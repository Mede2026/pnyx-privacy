import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// Couche de compatibilité iPhone/iPad/Mac : les vues partagées l'utilisent au lieu des API propres à UIKit.

#if canImport(UIKit)
typealias PlatformImage = UIImage
#else
typealias PlatformImage = NSImage

extension NSImage {
    convenience init?(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    func pngData() -> Data? {
        guard let tiff = tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}

extension Color {
    #if canImport(UIKit)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryFill = Color(.tertiarySystemFill)
    static let appBackground = Color(.systemBackground)
    #else
    static let groupedBackground = Color(nsColor: .windowBackgroundColor)
    static let secondaryGroupedBackground = Color(nsColor: .controlBackgroundColor)
    static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    static let tertiaryFill = Color(nsColor: .quaternaryLabelColor)
    static let appBackground = Color(nsColor: .windowBackgroundColor)
    #endif
}

extension View {
    func fieldKeyboard(_ keyboard: FieldKeyboard) -> some View {
        #if os(iOS)
        let type: UIKeyboardType = switch keyboard {
        case .url: .URL
        case .email: .emailAddress
        case .phone: .phonePad
        case .number: .numberPad
        case .decimal: .decimalPad
        case .numbersAndPunctuation: .numbersAndPunctuation
        }
        return keyboardType(type)
        #else
        return self
        #endif
    }

    func fieldContent(_ content: FieldContent) -> some View {
        #if os(iOS)
        let type: UITextContentType = switch content {
        case .url: .URL
        case .email: .emailAddress
        case .phone: .telephoneNumber
        case .password: .password
        case .username: .username
        case .givenName: .givenName
        case .familyName: .familyName
        case .organization: .organizationName
        case .street: .fullStreetAddress
        case .city: .addressCity
        case .state: .addressState
        case .postalCode: .postalCode
        case .country: .countryName
        }
        return textContentType(type)
        #else
        return self
        #endif
    }

    func noAutocapitalization() -> some View {
        #if os(iOS)
        return textInputAutocapitalization(.never)
        #else
        return self
        #endif
    }

    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        return navigationBarTitleDisplayMode(.inline)
        #else
        return self
        #endif
    }

    func sheetHeight(_ height: SheetHeight) -> some View {
        #if os(iOS)
        return presentationDetents(height == .medium ? [.medium] : [.medium, .large])
        #else
        return frame(minWidth: 420, minHeight: height == .medium ? 260 : 480)
        #endif
    }
}
