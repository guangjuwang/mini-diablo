// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MiniDiablo",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MiniDiabloCore", targets: ["MiniDiabloCore"])
    ],
    dependencies: [],
    targets: [
        .target(name: "MiniDiabloCore"),
        .testTarget(name: "MiniDiabloCoreTests", dependencies: ["MiniDiabloCore"])
    ],
    swiftLanguageVersions: [.v5]
)
