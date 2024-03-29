// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        .package(url: "https://github.com/colinta/Termbox.git", .branch("main")),
    ],
    targets: [
        .target(name: "Ashen", dependencies: ["Termbox"]),
        .testTarget(name: "AshenTests", dependencies: ["Ashen"]),
    ]
)
