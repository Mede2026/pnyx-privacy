import CryptoKit
import Foundation
import OSLog
import QRCore
import SwiftUI

/// Vignette d'un code dans une liste.
struct CodeThumbnail: View {
    let entry: CodeEntry
    var size: CGFloat = 44
    @State private var image: PlatformImage?

    var body: some View {
        let request = entry.renderRequest
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)
            if let image {
                Image(platformImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(3)
            } else {
                Image(systemName: entry.contentKind.symbolName)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.quaternary))
        .task(id: ThumbnailCache.key(id: entry.id, request: request)) {
            image = await ThumbnailCache.shared.image(id: entry.id, request: request)
        }
        .accessibilityHidden(true)
    }
}
