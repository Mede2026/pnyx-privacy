import ContactsUI
import EventKitUI
import MessageUI
import SafariServices
import SwiftUI

/// Présente les écrans système demandés par un ActionHandler, et le message éphémère « Copié ».
struct ActionPresentationsModifier: ViewModifier {
    @Bindable var handler: ActionHandler

    func body(content: Content) -> some View {
        content
            .sheet(item: $handler.presented) { presented in
                switch presented {
                case .safari(let url):
                    SafariView(url: url).ignoresSafeArea()
                case .contact(let contact):
                    ContactEditor(contact: contact) { handler.presented = nil }
                case .event(let event, let store):
                    EventEditor(event: event, store: store) { handler.presented = nil }
                case .message(let recipient, let body):
                    MessageComposer(recipient: recipient, body: body) { handler.presented = nil }
                }
            }
            .fullScreenCover(item: $handler.warning) { warning in
                SafeBrowsingWarningView(warning: warning) { handler.openDespiteWarning(warning.url) }
            }
            .overlay(alignment: .top) {
                if let toast = handler.toast {
                    ToastView(text: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: toast) {
                            guard await pause(.seconds(1.6)) else { return }
                            withAnimation { handler.toast = nil }
                        }
                }
            }
            .animation(.snappy, value: handler.toast)
    }
}

extension View {
    func actionPresentations(_ handler: ActionHandler) -> some View {
        modifier(ActionPresentationsModifier(handler: handler))
    }
}
