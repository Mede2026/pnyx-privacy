import QRCore
import SwiftUI

/// Interface commune des extensions : résultat du décodage ou QR du texte partagé.
struct ExtensionRootView: View {
    @Bindable var model: ExtensionModel
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .loading:
                    ProgressView("Analyse…")
                case .codes(let codes):
                    List(codes) { code in
                        DecodedCodeRow(code: code, model: model)
                    }
                case .text(let text):
                    SharedTextView(text: text, model: model)
                case .failed(let message):
                    ContentUnavailableView("Rien à afficher", systemImage: "qrcode.viewfinder",
                                           description: Text(message))
                }
            }
            .navigationTitle("QR Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK", action: onDone)
                }
            }
            .overlay(alignment: .bottom) {
                if let toast = model.toast {
                    Text(toast)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 24)
                        .task(id: toast) {
                            do {
                                try await Task.sleep(for: .seconds(1.5))
                                model.toast = nil
                            } catch {
                                return
                            }
                        }
                }
            }
        }
    }
}
