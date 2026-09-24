import PhotosUI
import QRCore
import SwiftUI

/// Logo central : image de la photothèque ou icône SF Symbols, de 10 à 25 % de la largeur.
struct LogoTab: View {
    @Binding var style: StyleConfig
    @Environment(AlertCenter.self) private var alerts
    @State private var photoItem: PhotosPickerItem?

    static let symbols = ["heart.fill", "star.fill", "wifi", "phone.fill", "envelope.fill", "cart.fill",
                          "house.fill", "cup.and.saucer.fill", "fork.knife", "music.note", "camera.fill",
                          "gift.fill", "leaf.fill", "pawprint.fill", "bolt.fill", "globe"]

    var body: some View {
        Section {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choisir une photo", systemImage: "photo")
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                ForEach(Self.symbols, id: \.self) { symbol in
                    Button {
                        setSymbol(symbol)
                    } label: {
                        Image(systemName: symbol)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(style.logoSymbolName == symbol ? Color.accentColor.opacity(0.2) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: SymbolNames.name(symbol)))
                }
            }
            if style.hasLogo {
                Button("Retirer le logo", systemImage: "xmark.circle", role: .destructive) {
                    style.logoPNG = nil
                    style.logoSymbolName = nil
                }
            }
        } header: {
            Text("Logo")
        } footer: {
            if style.hasLogo {
                Text("Avec un logo, la correction d’erreur passe au niveau H (30 %) pour que le code reste lisible.")
            }
        }
        if style.hasLogo {
            Section("Taille") {
                Slider(value: $style.logoScale, in: StyleConfig.logoScaleRange, step: 0.01) {
                    Text("Taille")
                } minimumValueLabel: {
                    Text("10 %")
                } maximumValueLabel: {
                    Text("25 %")
                }
            }
        }
        EmptyView()
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                photoItem = nil
                Task { await loadPhoto(item) }
            }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = PlatformImage(data: data),
                  let png = LogoImage.png(from: image) else {
                throw ImageBarcodeDecoder.DecodeError.unreadableImage
            }
            style.logoPNG = png
            style.logoSymbolName = nil
        } catch {
            alerts.show(error, title: String(localized: "La photo n’a pas pu être utilisée"))
        }
    }

    private func setSymbol(_ symbol: String) {
        guard let png = LogoImage.png(symbol: symbol, color: style.eyeFrameColor ?? style.foreground) else { return }
        style.logoPNG = png
        style.logoSymbolName = symbol
    }
}
