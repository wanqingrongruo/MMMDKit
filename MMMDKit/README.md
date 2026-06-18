# MMMDKit

MMMDKit v2 是面向 Apple 平台的 SwiftUI-only 模块化 Markdown 渲染框架，重点服务 AI 应用中的流式输出、列表渲染、代码高亮、表格、LaTeX、图片预览、链接点击、复制和国际化。

## 平台支持

- iOS 15.0+
- iPadOS 15.0+
- macOS 12.0+
- Swift 5.7+

## 模块

- `MMMDCore`：共享文档模型、主题、配置、插件、actions、国际化、图片缓存和复制模型。
- `MMMDParserSwiftMarkdown`：SPM 默认 parser，基于 `swift-markdown`。
- `MMMDParserCmark`：CocoaPods 默认 fallback parser。
- `MMMDStreaming`：独立流式 buffer、节流、稳定块和 metrics。
- `MMMDHighlighter`：代码高亮协议、默认 Swift keyword highlighter 和缓存 wrapper。
- `MMMDMath`：公式渲染协议和纯文本 fallback。
- `MMMDHTML`：HTML 清洗和 fallback 能力。
- `MMMDSwiftUI`：SwiftUI-only 渲染入口。
- `MMMDKit`：umbrella product。

## SPM

```swift
dependencies: [
    .package(url: "git@github.com:wanqingrongruo/MMMDKit.git", from: "0.2.0")
]
```

推荐：

```swift
.product(name: "MMMDKit", package: "MMMDKit")
```

按模块接入：

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

CocoaPods 不 vendoring `swift-markdown` / `swift-cmark`。Pods 默认使用 `MMMDParserCmark` fallback parser；如果需要与 SPM 完全一致的 `swift-markdown` 行为，推荐使用 SPM。

## SwiftUI 快速开始

```swift
import SwiftUI
import MMMDKit

struct ContentView: View {
    var body: some View {
        ScrollView {
            MarkdownText("""
            # Hello

            这是一段 **Markdown**，支持表格、代码块、公式和图片。
            """)
            .padding()
        }
    }
}
```

## 流式输出

```swift
import MMMDKit

let source = AsyncStream<String> { continuation in
    continuation.yield("# Hello\n\n")
    continuation.yield("Streaming **Markdown**")
    continuation.finish()
}

StreamingMarkdownText(source: source, inputMode: .delta)
```

`StreamingMarkdownText` 支持 `.delta` 和 `.snapshot` 两种输入模式。底层 `MarkdownRenderDiff.metrics` 会提供 chunk、render、parse latency、render latency 等指标，便于 demo 或业务监控面板展示。

## 自定义

`MarkdownConfiguration` 可以替换或定制：

- `theme`
- `localization`
- `codeHighlighter`
- `mathRenderer`
- `imageLoader`
- `layoutOptions`
- `actions`
- `plugins`

例如自定义链接和复制：

```swift
let configuration = MarkdownConfiguration(
    actions: MarkdownActions(
        onLinkTap: { url in print("open", url) },
        onCopyCode: { code, language in print("copied", language ?? "plain") }
    )
)

MarkdownText(markdown, configuration: configuration)
```

## v1 迁移

v2 不再公开 `MMMDUIKit` / `MMMDAppKit`。旧的 `MarkdownView`、`MarkdownNSView`、`MarkdownCollectionViewHost` 和 `MarkdownLayoutEngine` 不再是推荐 API。迁移说明见 [Migration v1 to v2](Docs/Migration-v1-to-v2.md)。

## 验证

```bash
swift build
swift test
```
