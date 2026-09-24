import ContactsUI
import EventKitUI
import MessageUI
import SafariServices
import SwiftUI

struct ToastView: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassCapsule()
            .padding(.top, 8)
            .accessibilityAddTraits(.isStaticText)
            .onAppear { Announcer.say(text) }
    }
}
