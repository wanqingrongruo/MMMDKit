# MMMDKit v2 Architecture

MMMDKit v2 是 SwiftUI-only 架构。UIKit/AppKit 只允许作为内部平台适配细节，不再作为公开渲染 API。

## 分层

```text
Markdown source
  -> MarkdownParser
  -> MarkdownDocument
  -> MarkdownConfiguration plugins
  -> MMMDSwiftUI block views
  -> SwiftUI ScrollView / List / LazyVStack
```

## 模块

- `MMMDCore`：纯模型、协议、主题、actions、国际化、复制 payload。
- `MMMDParserSwiftMarkdown`：SPM 默认 parser，依赖 `swift-markdown`。
- `MMMDParserCmark`：CocoaPods fallback parser。
- `MMMDStreaming`：parser 无关的流式状态、稳定块、节流和 metrics。
- `MMMDHighlighter`：代码高亮协议和默认实现。
- `MMMDMath`：公式渲染协议和 fallback。
- `MMMDHTML`：HTML sanitizer 和 fallback 策略。
- `MMMDSwiftUI`：唯一公开渲染层。
- `MMMDKit`：umbrella product。

## Parser 策略

SPM 下默认使用 `SwiftMarkdownParser`。它负责：

- 使用 `swift-markdown` 解析 CommonMark/GFM。
- 将 `Markdown.Document` 转成 `MarkdownDocument`。
- 在 parse 前处理 display/inline math。
- 在 streaming 阶段启用 incomplete Markdown speculative rewrite。

CocoaPods 下默认使用 `MMMDParserCmark` fallback parser，避免 vendoring `swift-markdown` / `swift-cmark`。

## SwiftUI 渲染

公开入口：

- `MarkdownText`
- `MarkdownDocumentView`
- `StreamingMarkdownText`

Block view 覆盖：

- paragraph / heading / list / blockquote / thematic break
- code block / table / math / image / HTML fallback

SwiftUI 渲染层通过 `MarkdownConfiguration` 读取 theme、localization、actions、highlighter、mathRenderer 和 imageLoader。

## Streaming

`StreamingMarkdownSession` 负责：

- delta 输入累积。
- 解析节流。
- `stableBlockCount`。
- `.streaming` / `.finished` phase。
- `MarkdownStreamingMetrics`。

`StreamingMarkdownText` 额外支持 snapshot 输入，并通过 `onUpdate` 把 diff 暴露给 demo 或业务监控面板。

## 交互

默认行为：

- link：SwiftUI `openURL`。
- copy：内部平台 pasteboard 适配。
- image preview：SwiftUI sheet。

业务可通过 `MarkdownActions` 覆盖 link、image、copy code、copy table、download、expand 等行为。

## 主题与国际化

- `MarkdownTheme.default` 使用 SwiftStreamingMarkdown 风格。
- 旧视觉基线不再保留为内置 API；业务需要旧样式时应通过 `MarkdownTheme` 显式声明。
- `MarkdownLocalization` 默认支持 English 和 Simplified Chinese，也支持业务传入自定义文案。
