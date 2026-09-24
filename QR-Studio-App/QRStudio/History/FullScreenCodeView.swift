import QRCore
import SwiftUI

/// Code en plein écran, luminosité au maximum, pour le montrer à quelqu'un.
struct FullScreenCodeView: View {
    let request: RenderRequest
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var previousBrightness: CGFloat?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 24) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                CodePreview(request: request, pixelWidth: 1400)
                    .padding()
            }
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.gray)
            }
            .padding()
            .accessibilityLabel(Text("Fermer"))
        }
        .onTapGesture { dismiss() }
        .onAppear {
            guard let screen = Self.screen else { return }
            previousBrightness = screen.brightness
            screen.brightness = 1
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            if let previousBrightness { Self.screen?.brightness = previousBrightness }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private static var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
    }
}
