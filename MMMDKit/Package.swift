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
        .library(name: "MMMDParserSwiftMarkdown", targets: ["MMMDParserSwiftMarkdown"]),
        .library(name: "MMMDStreaming", targets: ["MMMDStreaming"]),
        .library(name: "MMMDHighlighter", targets: ["MMMDHighlighter"]),
        .library(name: "MMMDMath", targets: ["MMMDMath"]),
        .library(name: "MMMDHTML", targets: ["MMMDHTML"]),
        .library(name: "MMMDSwiftUI", targets: ["MMMDSwiftUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.7.3")
    ],
    targets: [
        .target(
            name: "MMMDKit",
            dependencies: [
                "MMMDCore",
                "MMMDParserSwiftMarkdown",
                "MMMDStreaming",
                "MMMDHighlighter",
                "MMMDMath",
                "MMMDHTML",
                "MMMDSwiftUI"
            ]
        ),
        .target(name: "MMMDCore"),
        .target(name: "MMMDParserCmark", dependencies: ["MMMDCore"]),
        .target(
            name: "MMMDParserSwiftMarkdown",
            dependencies: [
                "MMMDCore",
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),
        .target(name: "MMMDStreaming", dependencies: ["MMMDCore"]),
        .target(name: "MMMDHighlighter", dependencies: ["MMMDCore"]),
        .target(name: "MMMDMath", dependencies: ["MMMDCore"]),
        .target(name: "MMMDHTML", dependencies: ["MMMDCore"]),
        .target(
            name: "MMMDSwiftUI",
            dependencies: [
                "MMMDCore",
                "MMMDStreaming",
                "MMMDParserSwiftMarkdown",
                "MMMDHighlighter",
                "MMMDMath",
                "MMMDHTML",
                "MMMDParserCmark"
            ]
        ),
        .testTarget(
            name: "MMMDCoreTests",
            dependencies: ["MMMDCore", "MMMDParserCmark", "MMMDParserSwiftMarkdown", "MMMDHighlighter", "MMMDHTML"]
        ),
        .testTarget(
            name: "MMMDStreamingTests",
            dependencies: ["MMMDCore", "MMMDStreaming", "MMMDParserSwiftMarkdown"]
        ),
        .testTarget(
            name: "MMMDPluginTests",
            dependencies: ["MMMDCore"]
        ),
        .testTarget(
            name: "MMMDSwiftUITests",
            dependencies: ["MMMDCore", "MMMDParserSwiftMarkdown", "MMMDSwiftUI"],
            resources: [.process("__Snapshots__")]
        )
    ]
)
