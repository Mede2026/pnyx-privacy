import AppIntents
import Foundation
import QRCore
import SwiftData
import SwiftUI

/// Aperçu affiché par Siri et les Raccourcis, sans lancer l'app.
struct CodeSnippetView: View {
    let image: PlatformImage
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(platformImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220, maxHeight: 220)
                .padding(10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            Text(title)
                .font(.headline)
                .lineLimit(1)
        }
        .padding()
    }
}
