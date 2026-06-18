# Migration v1 to v2

MMMDKit v2 是 SwiftUI-only breaking rewrite。v1 的 UIKit/AppKit 渲染入口不再作为公开 API 维护。

## 模块替换

| v1 | v2 |
| --- | --- |
| `MMMDUIKit` | `MMMDSwiftUI` |
| `MMMDAppKit` | `MMMDSwiftUI` |
| `MarkdownView` | `MarkdownText` 或 `MarkdownDocumentView` |
| `MarkdownNSView` | `MarkdownText` 或 `MarkdownDocumentView` |
| `MarkdownCollectionViewHost` | SwiftUI `ScrollView` / `List` / `LazyVStack` + `MarkdownText` |
| `MarkdownLayoutEngine` | SwiftUI 自适应布局；列表性能通过 demo metrics 观察 |

## 静态渲染

v1:

```swift
let parser = CmarkMarkdownParser()
let document = try parser.parse(markdown)
markdownView.render(document)
```

v2:

```swift
MarkdownText(markdown, configuration: configuration)
```

如果业务已经提前解析：

```swift
let document = try SwiftMarkdownParser().parse(markdown)
MarkdownDocumentView(document: document, configuration: configuration)
```

## 流式渲染

v2 支持 delta 和 snapshot 两种输入：

```swift
StreamingMarkdownText(source: stream, inputMode: .delta)
StreamingMarkdownText(source: stream, inputMode: .snapshot)
```

如果业务需要完全控制 session：

```swift
let session = StreamingMarkdownSession(parser: SwiftMarkdownParser())
StreamingMarkdownText(session: session)
```

## Parser 差异

- SPM 默认使用 `MMMDParserSwiftMarkdown`。
- CocoaPods 默认使用 `MMMDParserCmark` fallback parser。
- 如果需要完全一致的 GFM 行为，推荐使用 SPM。

## 自定义能力

以下能力继续通过 `MarkdownConfiguration` 注入：

- `codeHighlighter`
- `mathRenderer`
- `imageLoader`
- `actions`
- `plugins`
- `localization`
- `theme`

## 注意事项

- v2 不保证 v1 UIKit/AppKit 调用代码可直接迁移。
- 旧 UIKit/AppKit 源码和 demo 已从 v2 主线移除；请迁移到 `MMMDSwiftUI`。
- 默认主题已切到 SwiftStreamingMarkdown 风格；旧风格不再作为内置 API 保留。
