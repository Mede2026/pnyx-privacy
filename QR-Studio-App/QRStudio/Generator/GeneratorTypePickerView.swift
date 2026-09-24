import QRCore
import SwiftUI

/// Choix du type de contenu : grille d'icônes (iPhone) ou liste (colonne centrale sur iPad).
struct GeneratorTypePickerView: View {
    enum Style {
        case grid
        case list
    }

    let style: Style
    @Environment(AppRouter.self) private var router

    var body: some View {
        switch style {
        case .grid:
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 12) {
                    ForEach(ContentType.allCases) { type in
                        NavigationLink(value: type) {
                            VStack(spacing: 10) {
                                Image(systemName: type.symbolName)
                                    .font(.title)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(height: 36)
                                Text(type.title)
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 104)
                            .padding(8)
                            .background(Color.secondaryGroupedBackground,
                                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .navigationTitle("Créer")
        case .list:
            @Bindable var router = router
            List(ContentType.allCases, selection: $router.generatorType) { type in
                Label(type.title, systemImage: type.symbolName)
                    .tag(type)
            }
            .navigationTitle("Créer")
        }
    }
}
