# MMMDKit

MMMDKit 是面向 Apple 平台的模块化原生 Markdown 渲染框架，重点服务 AI 应用里的流式输出、原生滚动性能、复制与选择、无障碍、动态字体、代码高亮、表格、LaTeX 和 HTML fallback。

## 平台支持

- iOS 15.0+
- iPadOS 15.0+
- macOS 12.0+
- Swift 5.7+

## 设计目标

- 常见 Markdown 块使用原生 UIKit/AppKit 渲染。
- 各功能模块可以单独引入、单独使用。
- Parser、Renderer、Theme、Highlighter、MathRenderer、HTMLRenderer 都可以替换。
- AI 流式输出作为一等能力设计。
- iOS/iPadOS 使用 UIKit，macOS 使用 AppKit。
- 同时支持 CocoaPods 和 Swift Package Manager。

## 模块说明

- `MMMDCore`：共享文档模型、协议、主题、插件、无障碍和复制模型。
- `MMMDParserCmark`：Markdown/GFM 解析适配层，当前先提供占位解析器，后续接入 cmark-gfm。
- `MMMDStreaming`：流式 buffer、稳定块判断和渲染 diff。
- `MMMDHighlighter`：代码高亮协议和默认纯文本高亮实现。
- `MMMDMath`：LaTeX 渲染协议和 fallback 实现。
- `MMMDHTML`：HTML 渲染能力判断和 fallback 模型。
- `MMMDUIKit`：iOS/iPadOS 原生 UIKit 渲染入口。
- `MMMDAppKit`：macOS 原生 AppKit 渲染入口。
- `MMMDKit`：核心非 UI 模块的 umbrella product。

## Swift Package Manager

```swift
dependencies: [
    .package(url: "https://example.com/MMMDKit.git", from: "0.1.0")
]
```

引入完整核心库：

```swift
.product(name: "MMMDKit", package: "MMMDKit")
```

也可以按模块引入：

```swift
.product(name: "MMMDCore", package: "MMMDKit")
.product(name: "MMMDUIKit", package: "MMMDKit")
.product(name: "MMMDHighlighter", package: "MMMDKit")
```

## CocoaPods

```ruby
pod "MMMDKit"
```

按模块引入：

```ruby
pod "MMMDKit/Core"
pod "MMMDKit/ParserCmark"
pod "MMMDKit/UIKit"
pod "MMMDKit/AppKit"
```

## 项目状态

当前仓库已经包含架构文档、包结构、模块协议、UIKit/AppKit demo 源码骨架和基础单元测试。实现顺序见 `Docs/Roadmap.md` 和 `Docs/TODO.md`。
