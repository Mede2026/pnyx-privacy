import Contacts
import EventKit
import Foundation
import MessageUI
import NetworkExtension
import Observation
import OSLog
import QRCore
import UIKit

/// Écrans système présentés par une action (Safari intégré, contact, événement, message).
enum PresentedAction: Identifiable {
    case safari(URL)
    case contact(CNMutableContact)
    case event(EKEvent, EKEventStore)
    case message(recipient: String, body: String)

    var id: String {
        switch self {
        case .safari(let url): "safari-\(url.absoluteString)"
        case .contact: "contact"
        case .event: "event"
        case .message(let recipient, _): "message-\(recipient)"
        }
    }
}
