import SwiftUI

/// Bande fixée sous la barre de navigation. Sur iOS 26, elle s'intègre à la barre
/// (safeAreaBar, avec l'effet de bord de défilement du système) ; avant, fond de barre classique.
struct TopBarModifier<Bar: View>: ViewModifier {
    @ViewBuilder var bar: Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content.safeAreaBar(edge: .top, spacing: 0) { bar }
        } else {
            content.safeAreaInset(edge: .top, spacing: 0) { bar.background(.bar) }
        }
    }
}
