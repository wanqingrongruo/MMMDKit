# MMMDKit 架构设计

## 产品定位

MMMDKit 不是简单的“Markdown 转富文本”工具，而是面向 AI 输出和复杂文档的 Apple 原生 Markdown 渲染框架。

框架围绕以下原则设计：

- Parser 可替换。
- Block Model 保持稳定。
- Renderer 可注册、可替换。
- 复杂能力按独立模块拆分。
- iOS/iPadOS 使用 UIKit，macOS 使用 AppKit。
- AI 流式输出作为一等能力。

## 渲染管线

```text
Markdown Source
  -> Parser
  -> MarkdownDocument
  -> Plugins
  -> Layout Model
  -> Native Block Renderer
  -> Selection / Copy / Accessibility / Dynamic Type
```

For AI streaming:

```text
Token Delta
  -> Streaming Buffer
  -> Throttled Parse
  -> Stable Blocks + Unstable Tail
  -> Render Diff
  -> Native UI Commit
```

## 模块边界

### MMMDCore

负责所有共享契约：

- `MarkdownDocument`
- `MarkdownBlock`
- `InlineNode`
- `MarkdownParser`
- `MarkdownPlugin`
- `MarkdownConfiguration`
- `MarkdownTheme`
- `RenderContext`
- `AccessibilityNode`
- `CopyPayload`

它不依赖 UIKit、AppKit、WebKit 或 JavaScript。

### MMMDParserCmark

负责 cmark-gfm 适配层。后续会绑定真实 cmark-gfm，并输出稳定的 MMMDKit 文档模型。公开 API 不暴露 cmark 内部类型。

### MMMDStreaming

负责 AI 流式处理。它接收文本 delta，输出渲染 diff，不感知具体 UI 容器。

### MMMDHighlighter

负责代码高亮协议与实现，输出语义化高亮 token，不直接返回 UIKit/AppKit 视图。

### MMMDMath

负责 LaTeX 渲染协议和可缓存渲染结果。默认实现可以是 fallback，生产实现可以接入 KaTeX、MathJax、iosMath 或自定义引擎。

### MMMDHTML

负责 HTML 能力判断和 fallback 结果。简单 HTML 可以映射到原生 inline，复杂 HTML 隔离到 WebView block。

### MMMDUIKit

负责 iOS/iPadOS 原生渲染：

- `MarkdownView`
- block host collection view
- block cells
- link tap, copy, menu, accessibility, dynamic type

### MMMDAppKit

负责 macOS 原生渲染：

- `MarkdownNSView`
- NSCollectionView host
- AppKit 菜单、hover、无障碍、复制

## 自定义点

每个核心子系统都应该可以替换：

```swift
configuration.parser = MyParser()
configuration.highlighter = MyHighlighter()
configuration.mathRenderer = MyMathRenderer()
configuration.htmlRenderer = MyHTMLRenderer()
configuration.plugins = [MentionPlugin(), MermaidPlugin()]
```

Block renderer 按 block 类型注册：

```swift
configuration.registerBlockRenderer(.code, renderer: MyCodeRenderer())
```

## 复杂内容策略

### 代码块

代码块是独立原生组件，包含语言标签、复制按钮、横向滚动、异步高亮和高度缓存。

### 表格

表格是独立可横向滚动 block。单元格支持 inline Markdown，列宽测量可缓存，未来支持大表格虚拟化。

### LaTeX

数学公式渲染是插件能力。inline math 可嵌入段落渲染，display math 使用独立 block。

### HTML

HTML 分层支持：

```text
安全 inline HTML -> 原生 inline
已知 block HTML -> 原生 block
复杂 HTML -> WKWebView fallback block
```

## 性能规则

- Markdown 解析放到主线程外。
- UI commit 只在主线程执行。
- 流式输出需要节流。
- 稳定 block 冻结，只更新不稳定尾块。
- layout cache 需要包含宽度、动态字体、主题和平台 trait。
- 代码高亮异步执行。
- token streaming 阶段避免整篇文档 reload。
