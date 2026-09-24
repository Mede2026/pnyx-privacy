import OSLog
import SwiftUI
import UIKit

/// Choix de l'icône de l'app (icônes alternatives d'iOS).
struct AppIconPickerView: View {
    @Environment(AlertCenter.self) private var alerts
    @State private var selection = AppIconChoice(alternateIconName: UIApplication.shared.alternateIconName)

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 20)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(AppIconChoice.allCases) { choice in
                    Button {
                        Task { await apply(choice) }
                    } label: {
                        VStack(spacing: 8) {
                            choice.preview
                                .resizable()
                                .scaledToFit()
                                .frame(width: 76, height: 76)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color.accentColor, lineWidth: selection == choice ? 3 : 0)
                                        .padding(-5)
                                }
                            Text(choice.title)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(choice.title))
                    .accessibilityAddTraits(selection == choice ? .isSelected : [])
                }
            }
            .padding()
        }
        .navigationTitle("Icône de l’app")
        .disabled(!UIApplication.shared.supportsAlternateIcons)
    }

    private func apply(_ choice: AppIconChoice) async {
        guard choice != selection else { return }
        do {
            try await UIApplication.shared.setAlternateIconName(choice.alternateIconName)
            selection = choice
        } catch {
            Logger.general.error("Icône non changée : \(error.localizedDescription)")
            alerts.show(error)
        }
    }
}
