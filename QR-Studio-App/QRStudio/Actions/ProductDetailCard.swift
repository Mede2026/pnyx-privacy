import QRCore
import SwiftData
import SwiftUI

/// Code produit (EAN, UPC ou GS1 Digital Link) : code groupé, pays GS1, somme de contrôle,
/// lien du fabricant et sites de recherche configurables.
struct ProductDetailCard: View {
    let product: ProductInfo
    let actions: ActionHandler
    @Environment(AppSettings.self) private var settings
    @Query(filter: #Predicate<SearchSite> { $0.isEnabled }, sort: \SearchSite.sortOrder) private var sites: [SearchSite]
    @State private var lookup: LookupState = .idle

    enum LookupState: Equatable {
        case idle, loading, found(String), failed(String)
    }

    var body: some View {
        VStack(spacing: 12) {
            CardSection {
                if product.isDigitalLink {
                    Label("Fiche produit", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
                Text(GTIN.formatted(product.code))
                    .font(.title.bold().monospacedDigit())
                    .textSelection(.enabled)
                LabeledContent("Somme de contrôle") {
                    Label(product.isChecksumValid ? "Valide" : "Invalide",
                          systemImage: product.isChecksumValid ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .foregroundStyle(product.isChecksumValid ? .green : .red)
                }
                if let country = GTIN.registrationCountry(for: product.code) {
                    LabeledContent("Préfixe GS1", value: country)
                    Text("Ce préfixe indique le pays où l’entreprise a enregistré son code, pas le pays de fabrication.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                lookupRow
            }
            VStack(spacing: 8) {
                if let manufacturer = product.manufacturerURL {
                    Button {
                        actions.openInApp(manufacturer)
                    } label: {
                        Label("Voir la fiche du fabricant", systemImage: "building.2")
                            .frame(maxWidth: .infinity)
                    }
                    .glassButtonStyle(prominent: true)
                    .controlSize(.large)
                }
                ForEach(sites) { site in
                    if let url = site.url(for: product.searchCode) {
                        Button {
                            actions.openInApp(url)
                        } label: {
                            Label("Chercher sur \(site.name)", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .glassButtonStyle()
                        .controlSize(.large)
                    }
                }
                Button {
                    actions.copy(product.code)
                } label: {
                    Label("Copier le code", systemImage: "doc.on.doc").frame(maxWidth: .infinity)
                }
                .glassButtonStyle()
                .controlSize(.large)
            }
        }
        .task(id: product.gtin) {
            if settings.linkPreviews { await lookUp() }
        }
    }

    @ViewBuilder
    private var lookupRow: some View {
        switch lookup {
        case .idle:
            Button("Afficher le nom du produit (Open Food Facts)", systemImage: "fork.knife") {
                Task { await lookUp() }
            }
            .font(.callout)
        case .loading:
            ProgressView().frame(maxWidth: .infinity, alignment: .leading)
        case .found(let name):
            LabeledContent("Produit", value: name)
        case .failed(let message):
            Text(message).font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func lookUp() async {
        lookup = .loading
        do {
            let result = try await OpenFoodFactsClient.lookup(code: product.searchCode)
            lookup = .found(result.displayName ?? product.code)
        } catch {
            lookup = .failed(error.localizedDescription)
        }
    }
}
