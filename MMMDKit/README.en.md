# MMMDKit

MMMDKit v2 is a SwiftUI-only, modular Markdown rendering framework for Apple platforms. It is designed for AI streaming output, list rendering, syntax highlighting, tables, LaTeX, image preview, link handling, copy actions, and localization.

## Platforms

- iOS 15.0+
- iPadOS 15.0+
- macOS 12.0+
- Swift 5.7+

## Modules

- `MMMDCore`: shared document model, theme, configuration, plugins, actions, localization, image caching, and copy payloads.
- `MMMDParserSwiftMarkdown`: the default SPM parser, backed by `swift-markdown`.
- `MMMDParserCmark`: the CocoaPods fallback parser.
- `MMMDStreaming`: independent streaming buffer, throttling, stable block count, and metrics.
- `MMMDHighlighter`: code highlighting protocol, the default Swift keyword highlighter, and a caching wrapper.
- `MMMDMath`: math rendering protocol and plain-text fallback.
- `MMMDHTML`: HTML sanitizing and fallback support.
- `MMMDSwiftUI`: SwiftUI-only rendering entry points.
- `MMMDKit`: umbrella product.

## Swift Package Manager

```swift
dependencies: [
    .package(url: "git@github.com:wanqingrongruo/MMMDKit.git", from: "0.2.0")
]
```

Recommended product:

```swift
.product(name: "MMMDKit", package: "MMMDKit")
```

Modular products:

```swift
.product(name: "MMMDCore", package: "MMMDKit")
.product(name: "MMMDParserSwiftMarkdown", package: "MMMDKit")
.product(name: "MMMDStreaming", package: "MMMDKit")
.product(name: "MMMDSwiftUI", package: "MMMDKit")
```

## CocoaPods

```ruby
pod "MMMDKit"
```

CocoaPods does not vendor `swift-markdown` or `swift-cmark`. Pod integrations use the `MMMDParserCmark` fallback parser by default. Use SPM when you need the default `swift-markdown` behavior.

## Quick Start

```swift
import SwiftUI
import MMMDKit

struct ContentView: View {
    var body: some View {
        ScrollView {
            MarkdownText("""
            # Hello

            MMMDKit supports **Markdown**, tables, code blocks, math, and images.
            """)
            .padding()
        }
    }
}
```

## Streaming

```swift
let source = AsyncStream<String> { continuation in
    continuation.yield("# Hello\n\n")
    continuation.yield("Streaming **Markdown**")
    continuation.finish()
}

StreamingMarkdownText(source: source, inputMode: .delta)
```

`StreamingMarkdownText` supports both `.delta` and `.snapshot` inputs. `MarkdownRenderDiff.metrics` exposes chunk count, render count, parse latency, render latency, and elapsed time for demos and production monitoring.

## Customization

`MarkdownConfiguration` can customize:

- `theme`
- `localization`
- `codeHighlighter`
- `mathRenderer`
- `imageLoader`
- `layoutOptions`
- `actions`
- `plugins`

## Migration

v2 no longer exposes `MMMDUIKit` or `MMMDAppKit`. The old `MarkdownView`, `MarkdownNSView`, `MarkdownCollectionViewHost`, and `MarkdownLayoutEngine` APIs are replaced by SwiftUI entry points. See [Migration v1 to v2](Docs/Migration-v1-to-v2.md).
