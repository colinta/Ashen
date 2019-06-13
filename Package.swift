// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Ashen",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "Ashen", targets: ["Ashen"]),
    ],
    dependencies: [
        // .package(url: "https://github.com/colinta/Termbox.git", .exact("1.0.0-alpha.3")),
        .package(path: "../Termbox"),
    ],
    targets: [
        .target(name: "Ashen", dependencies: ["Termbox"]),
        // .target(name: "Ashen"),
    ]
    )
