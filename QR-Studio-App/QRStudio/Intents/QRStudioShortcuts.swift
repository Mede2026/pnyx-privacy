import AppIntents

/// Phrases Siri et actions proposées dans Spotlight. Le nom de l'app figure dans chaque phrase.
struct QRStudioShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanCodeIntent(),
            phrases: [
                "Scanne un code avec \(.applicationName)",
                "Scanner un code avec \(.applicationName)",
                "Ouvre le scanner de \(.applicationName)"
            ],
            shortTitle: "Scanner",
            systemImageName: "qrcode.viewfinder"
        )
        AppShortcut(
            intent: CreateQRFromTextIntent(),
            phrases: [
                "Crée un QR avec \(.applicationName)",
                "Créer un code QR avec \(.applicationName)"
            ],
            shortTitle: "Créer un QR",
            systemImageName: "plus.square.on.square"
        )
        AppShortcut(
            intent: CreateQRFromClipboardIntent(),
            phrases: [
                "Crée un QR du presse-papier avec \(.applicationName)",
                "Crée un QR à partir du presse-papier dans \(.applicationName)"
            ],
            shortTitle: "QR du presse-papier",
            systemImageName: "doc.on.clipboard"
        )
        AppShortcut(
            intent: ShowCodeIntent(),
            phrases: [
                "Montre \(\.$code) dans \(.applicationName)",
                "Affiche \(\.$code) dans \(.applicationName)",
                "Montre mon code dans \(.applicationName)"
            ],
            shortTitle: "Afficher un code",
            systemImageName: "qrcode"
        )
        AppShortcut(
            intent: ShowWiFiIntent(),
            phrases: [
                "Montre mon code Wi-Fi dans \(.applicationName)",
                "Affiche le code Wi-Fi dans \(.applicationName)",
                "Partage le Wi-Fi avec \(.applicationName)"
            ],
            shortTitle: "Code Wi-Fi",
            systemImageName: "wifi"
        )
        AppShortcut(
            intent: LastScanIntent(),
            phrases: [
                "Quel était mon dernier scan dans \(.applicationName)",
                "Dernier scan dans \(.applicationName)"
            ],
            shortTitle: "Dernier scan",
            systemImageName: "clock.arrow.circlepath"
        )
    }
}
