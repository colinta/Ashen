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
        .package(url: "https://github.com/colinta/Termbox.git", .revision("54871b8")),
    ],
    targets: [
        .target(name: "Ashen", dependencies: ["Termbox"]),
        // .target(name: "Ashen"),
    ]
    )
