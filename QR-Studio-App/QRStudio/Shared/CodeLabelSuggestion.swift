import Foundation
import FoundationModels
import OSLog
import QRCore

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct CodeLabelSuggestion {
    @Guide(description: "Short label, 4 words maximum, in the user's language")
    let label: String

    @Guide(description: "Name of the most appropriate folder among those provided, or an empty string")
    let suggestedFolder: String
}
