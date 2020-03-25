// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Ashen",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .library(name: "Ashen", targets: ["Ashen"]),
    ],
    dependencies: [
        .package(url: "https://github.com/colinta/Termbox.git", .branch("master")),
    ],
    targets: [
        .target(name: "Ashen", dependencies: ["Termbox"]),
        .testTarget(name: "AshenTests", dependencies: ["Ashen"]),
    ]
)
