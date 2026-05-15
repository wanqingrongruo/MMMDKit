// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "MMMDKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "MMMDKit", targets: ["MMMDKit"]),
        .library(name: "MMMDCore", targets: ["MMMDCore"]),
        .library(name: "MMMDParserCmark", targets: ["MMMDParserCmark"]),
        .library(name: "MMMDStreaming", targets: ["MMMDStreaming"]),
        .library(name: "MMMDHighlighter", targets: ["MMMDHighlighter"]),
        .library(name: "MMMDMath", targets: ["MMMDMath"]),
        .library(name: "MMMDHTML", targets: ["MMMDHTML"]),
        .library(name: "MMMDUIKit", targets: ["MMMDUIKit"]),
        .library(name: "MMMDAppKit", targets: ["MMMDAppKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/mgriebling/SwiftMath.git", from: "1.7.3")
    ],
    targets: [
        .target(
            name: "MMMDKit",
            dependencies: [
                "MMMDCore",
                "MMMDParserCmark",
                "MMMDStreaming",
                "MMMDHighlighter",
                "MMMDMath",
                "MMMDHTML"
            ]
        ),
        .target(name: "MMMDCore"),
        .target(name: "MMMDParserCmark", dependencies: ["MMMDCore"]),
        .target(name: "MMMDStreaming", dependencies: ["MMMDCore"]),
        .target(name: "MMMDHighlighter", dependencies: ["MMMDCore"]),
        .target(name: "MMMDMath", dependencies: ["MMMDCore"]),
        .target(name: "MMMDHTML", dependencies: ["MMMDCore"]),
        .target(
            name: "MMMDUIKit",
            dependencies: [
                "MMMDCore",
                "MMMDStreaming",
                "MMMDHighlighter",
                "MMMDMath",
                "MMMDHTML",
                .product(name: "SwiftMath", package: "SwiftMath")
            ]
        ),
        .target(
            name: "MMMDAppKit",
            dependencies: [
                "MMMDCore",
                "MMMDStreaming",
                "MMMDHighlighter",
                "MMMDMath",
                "MMMDHTML",
                .product(name: "SwiftMath", package: "SwiftMath")
            ]
        ),
        .testTarget(
            name: "MMMDCoreTests",
            dependencies: ["MMMDCore", "MMMDParserCmark", "MMMDHighlighter", "MMMDHTML"]
        ),
        .testTarget(
            name: "MMMDStreamingTests",
            dependencies: ["MMMDCore", "MMMDStreaming", "MMMDParserCmark"]
        ),
        .testTarget(
            name: "MMMDPluginTests",
            dependencies: ["MMMDCore"]
        ),
        .testTarget(
            name: "MMMDAppKitTests",
            dependencies: ["MMMDAppKit"]
        ),
        .testTarget(
            name: "MMMDUIKitTests",
            dependencies: ["MMMDUIKit"]
        )
    ]
)
