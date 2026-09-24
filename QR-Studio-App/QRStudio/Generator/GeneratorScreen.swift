import QRCore
import SwiftUI

/// Onglet Créer (disposition compacte) : grille des types, puis formulaire poussé.
struct GeneratorScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var path: [ContentType] = []

    var body: some View {
        NavigationStack(path: $path) {
            GeneratorTypePickerView(style: .grid)
                .navigationDestination(for: ContentType.self) { type in
                    GeneratorFormView(type: type)
                }
        }
        .onChange(of: router.generatorType, initial: true) { _, type in
            // Ouverture depuis un raccourci ou l'extension de partage.
            guard let type, router.selectedTab == .create else { return }
            path = [type]
            router.generatorType = nil
        }
    }
}
