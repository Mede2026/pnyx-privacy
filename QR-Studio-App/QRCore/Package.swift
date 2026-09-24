// swift-tools-version: 6.0
// Package local partagé par toutes les cibles de QR Studio.
// Aucune dépendance externe : uniquement des frameworks Apple.
import PackageDescription

let package = Package(
    name: "QRCore",
    defaultLocalization: "fr",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10)],
    products: [
        .library(name: "QRCore", targets: ["QRCore"])
    ],
    targets: [
        .target(
            name: "QRCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "QRCoreTests",
            dependencies: ["QRCore"]
        )
    ]
)
