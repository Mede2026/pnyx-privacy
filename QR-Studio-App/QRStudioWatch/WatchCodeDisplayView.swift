import QRCore
import SwiftData
import SwiftUI
import WatchKit

/// Code en plein écran, sur fond blanc, pour le faire scanner.
/// watchOS n'offre aucune API pour régler la luminosité ni pour garder l'écran allumé
/// (isFrontmostTimeoutExtended n'est plus pris en charge depuis watchOS 7) :
/// le fond blanc plein écran donne la luminance maximale.
struct WatchCodeDisplayView: View {
    let entryID: UUID
    @Environment(\.modelContext) private var context
    @State private var entry: CodeEntry?
    @State private var image: UIImage?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            if let entry, WatchDisplay.isTooDense(entry.rawValue) {
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("Ce code est trop dense pour l’écran de la montre. Affichez-le sur l’iPhone.")
                        .font(.footnote)
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .accessibilityLabel(Text(entry?.displayTitle ?? "Code"))
            } else if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.black).multilineTextAlignment(.center)
            } else {
                ProgressView().tint(.black)
            }
        }
        .navigationTitle(entry?.displayTitle ?? "")
        .persistentSystemOverlays(.hidden)
        .task { await load() }
    }

    private func load() async {
        let id = entryID
        var descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        do {
            guard let found = try context.fetch(descriptor).first else {
                errorMessage = String(localized: "Ce code n’existe plus.")
                return
            }
            entry = found
            guard !WatchDisplay.isTooDense(found.rawValue) else { return }
            guard let request = WatchDisplay.request(payload: found.rawValue, symbology: found.symbology) else {
                errorMessage = String(localized: "Ce format (\(found.symbologyKind.displayName)) ne peut pas s’afficher sur la montre. Affichez-le sur l’iPhone.")
                return
            }
            image = try await WatchCodeImage.render(request, width: 400)
            // Petit retour haptique : le code est prêt à présenter.
            WKInterfaceDevice.current().play(.click)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
