import ContactsUI
import EventKitUI
import MessageUI
import SafariServices
import SwiftUI

struct ContactEditor: UIViewControllerRepresentable {
    let contact: CNMutableContact
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = CNContactViewController(forNewContact: contact)
        controller.contactStore = CNContactStore()
        controller.delegate = context.coordinator
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ controller: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, CNContactViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            onFinish()
        }
    }
}
