import Foundation
import Testing
@testable import QRCore

/// Essai réel contre l'API Google, lancé seulement si une clé est fournie :
/// SAFE_BROWSING_TEST_KEY=… swift test --filter SafeBrowsingLiveTests
@Suite("Safe Browsing : API réelle",
       .enabled(if: ProcessInfo.processInfo.environment["SAFE_BROWSING_TEST_KEY", default: ""].isEmpty == false))
struct SafeBrowsingLiveTests {
    private var key: String? { ProcessInfo.processInfo.environment["SAFE_BROWSING_TEST_KEY"] }

    /// Pages de test officielles de Google (testsafebrowsing.appspot.com).
    @Test func googleTestPagesAreFlagged() async throws {
        let key = try #require(key)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let client = SafeBrowsingClient(directory: directory, bundleIdentifier: "app.qrstudio")
        try await client.updateIfNeeded(apiKey: key)
        #expect(await client.hasDatabase)

        let base = "http://testsafebrowsing.appspot.com/s/"
        let cases: [(String, SafeBrowsingVerdict)] = [
            (base + "phishing.html", .unsafe(.socialEngineering)),
            (base + "malware.html", .unsafe(.malware)),
            (base + "unwanted.html", .unsafe(.unwantedSoftware)),
            ("https://www.apple.com/fr/", .safe)
        ]
        for (raw, expected) in cases {
            let url = try #require(URL(string: raw))
            #expect(await client.check(url, apiKey: key) == expected, "\(raw)")
        }

        // Mise à jour suivante : partielle, relue depuis le disque.
        let reloaded = SafeBrowsingClient(directory: directory, bundleIdentifier: "app.qrstudio")
        #expect(await reloaded.hasDatabase)
        try FileManager.default.removeItem(at: directory)
    }
}
