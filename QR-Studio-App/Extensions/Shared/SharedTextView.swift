import QRCore
import SwiftUI

/// Texte ou lien partagé : son QR, prêt à enregistrer ou copier en deux gestes.
struct SharedTextView: View {
    let text: String
    let model: ExtensionModel
    @State private var image: UIImage?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Group {
                    if let image {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                    } else if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: 260, minHeight: 260)
                .padding()
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))

                Text(text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.center)

                Button {
                    model.save(payload: text, symbology: .qr, origin: .generated)
                } label: {
                    Label(model.savedPayloads.contains(text) ? "Enregistré" : "Enregistrer dans l’historique",
                          systemImage: model.savedPayloads.contains(text) ? "checkmark" : "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.savedPayloads.contains(text) || image == nil)

                Button {
                    model.customizeInApp(text)
                } label: {
                    Label("Personnaliser dans QR Studio", systemImage: "paintpalette").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if let image {
                    Button {
                        model.copy(image: image)
                    } label: {
                        Label("Copier l’image", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .task {
            do {
                let drawing = try await CodeRenderer.shared.drawing(for: RenderRequest(payload: text, symbology: .qr))
                image = UIImage(data: try drawing.pngData(width: 600))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
