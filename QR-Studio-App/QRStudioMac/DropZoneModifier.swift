import QRCore
import SwiftUI
import UniformTypeIdentifiers

/// Glisser-déposer d'une image sur la fenêtre pour la décoder.
struct DropZoneModifier: ViewModifier {
    @Environment(AppServices.self) private var services
    @State private var isTargeted = false

    func body(content: Content) -> some View {
        content
            .onDrop(of: [.fileURL, .image], isTargeted: $isTargeted) { providers in
                Task { await decode(providers) }
                return true
            }
            .overlay {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 4, dash: [10, 6]))
                        .background(Color.accentColor.opacity(0.08))
                        .overlay {
                            Label("Déposez une image pour lire son code", systemImage: "qrcode.viewfinder")
                                .font(.title3.weight(.semibold))
                                .padding()
                                .background(.regularMaterial, in: Capsule())
                        }
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
    }

    private func decode(_ providers: [NSItemProvider]) async {
        var images: [Data] = []
        do {
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    let urlData = try await provider.loadData(for: .fileURL)
                    guard let url = URL(dataRepresentation: urlData, relativeTo: nil) else { continue }
                    images.append(try Data(contentsOf: url))
                } else {
                    images.append(try await provider.loadData(for: .image))
                }
            }
        } catch {
            services.alerts.show(error, title: String(localized: "Image illisible"))
            return
        }
        // Un code glissé depuis cette même fenêtre ne doit pas se réimporter en double.
        guard !DraggableCode.wasJustExported else { return }
        await MacImageImporter.decode(images: images)
    }
}

extension View {
    func imageDropZone() -> some View {
        modifier(DropZoneModifier())
    }
}
