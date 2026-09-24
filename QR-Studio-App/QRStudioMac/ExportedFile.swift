import QRCore
import SwiftUI
import UniformTypeIdentifiers

/// Document exporté via le panneau d'enregistrement du système.
struct ExportedFile: FileDocument {
    static let readableContentTypes: [UTType] = [.png, .jpeg, .pdf, .svg, .commaSeparatedText, .json]
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
