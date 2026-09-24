import SwiftUI

/// Carte groupant des lignes, au style des feuilles.
struct CardSection<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
