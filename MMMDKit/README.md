# MMMDKit

MMMDKit 是面向 Apple 平台的模块化原生 Markdown 渲染框架，重点服务 AI 应用中的流式输出、原生滚动性能、复制与选择、无障碍、动态字体、代码高亮、表格、LaTeX 和 HTML fallback。

## 平台支持

- iOS 15.0+
- iPadOS 15.0+
- macOS 12.0+
- Swift 5.7+

## 能力概览

- 原生 UIKit/AppKit 渲染：常见 Markdown 块会映射到系统视图，而不是 WebView 整页渲染。
- 流式输出：内置 `StreamingMarkdownSession`，业务只需要不断追加上游返回的新文本。
- 布局测量：提供 `MarkdownLayoutEngine`，列表和聊天气泡可以提前计算 Markdown 内容尺寸。
- 可替换能力：Parser、代码高亮、公式渲染、图片加载、HTML 策略都通过协议注入。
- 模块化接入：可以只引入模型和解析，也可以按平台引入 UIKit/AppKit 渲染层。
- AI 场景优化：流式尾部代码块不会反复异步高亮，稳定块会复用高亮缓存。

## 模块说明

- `MMMDCore`：共享文档模型、协议、主题、插件、复制模型和渲染配置。
- `MMMDParserCmark`：Markdown/GFM 解析入口，将 Markdown 文本转换为 `MarkdownDocument`。
- `MMMDStreaming`：流式 buffer、稳定块判断、节流会话和渲染 diff。
- `MMMDHighlighter`：代码高亮协议，以及纯文本和 Swift 关键字高亮实现。
- `MMMDMath`：LaTeX 渲染协议和纯文本 fallback 实现。
- `MMMDHTML`：HTML 清洗与渲染能力判断。
- `MMMDUIKit`：iOS/iPadOS 原生渲染入口 `MarkdownView`。
- `MMMDAppKit`：macOS 原生渲染入口 `MarkdownNSView`。
- `MMMDKit`：非 UI 核心模块的 umbrella product。

## Swift Package Manager

```swift
dependencies: [
    .package(url: "git@github.com:wanqingrongruo/MMMDKit.git", from: "0.1.0")
]
```

iOS/iPadOS 应用通常选择：

```swift
.product(name: "MMMDParserCmark", package: "MMMDKit")
.product(name: "MMMDUIKit", package: "MMMDKit")
```

macOS 应用通常选择：

```swift
.product(name: "MMMDParserCmark", package: "MMMDKit")
.product(name: "MMMDAppKit", package: "MMMDKit")
```

只做解析、流式处理或服务端预处理时，可以按需选择：

```swift
.product(name: "MMMDCore", package: "MMMDKit")
.product(name: "MMMDParserCmark", package: "MMMDKit")
.product(name: "MMMDStreaming", package: "MMMDKit")
```

SPM 是当前推荐接入方式。通过 SPM 引入 `MMMDUIKit` / `MMMDAppKit` 时，会传递引入 SwiftMath，`$$...$$` block math 默认使用原生公式排版。

## CocoaPods

完整核心库：

```ruby
pod "MMMDKit"
```

按模块引入：

```ruby
pod "MMMDCore"
pod "MMMDParserCmark"
pod "MMMDStreaming"
pod "MMMDHighlighter"
pod "MMMDMath"
pod "MMMDHTML"
pod "MMMDUIKit"   # iOS/iPadOS
pod "MMMDAppKit"  # macOS
```

注意：CocoaPods 集成不会自动引入 `mgriebling/SwiftMath`。因此 CocoaPods 下公式块会 fallback 为 LaTeX 文本显示；如果需要真实公式排版，需要业务侧自行提供 `MarkdownConfiguration.mathRenderer`，或 vendoring 一个 CocoaPods 可用的公式渲染实现。

## 快速开始

### UIKit 静态渲染

```swift
import MMMDCore
import MMMDParserCmark
import MMMDHighlighter
import MMMDUIKit

let parser = CmarkMarkdownParser()
let markdownView = MarkdownView()
markdownView.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(markdownView)

let configuration = MarkdownConfiguration(
    codeHighlighter: KeywordCodeHighlighter(),
    codeBlockMaximumWidth: 640
)
markdownView.configuration = configuration

let document = try parser.parse("# Hello\n\n这是一段 **Markdown**。")
markdownView.render(document)
```

### UIKit 流式渲染

```swift
markdownView.startStreaming(parser: CmarkMarkdownParser())

for await delta in aiTextStream {
    markdownView.appendStreamingText(delta)
}

markdownView.finishStreaming()
```

### 内容尺寸测量

```swift
let layout = MarkdownLayoutEngine.measure(
    document: document,
    fittingWidth: 320,
    configuration: configuration
)

print(layout.size.height)
```

### macOS 渲染

macOS 使用 `MarkdownNSView`，其余配置方式与 UIKit 基本一致：

```swift
import MMMDCore
import MMMDParserCmark
import MMMDHighlighter
import MMMDAppKit

let markdownView = MarkdownNSView()
markdownView.configuration = MarkdownConfiguration(codeHighlighter: KeywordCodeHighlighter())
markdownView.render(try CmarkMarkdownParser().parse(markdown))
```

## 详细教程

完整接入步骤、配置项、SwiftUI 包装、流式策略、自定义高亮/图片/公式等内容，请查看 [MMMDKit 使用与配置教程](Docs/UsageTutorial.md)。

## 开发验证

```bash
swift test
xcodebuild build -project ../MMMDKitDemos/iOSDemo/MMMDKitiOSDemo.xcodeproj -scheme MMMDKitiOSDemo -destination 'generic/platform=iOS Simulator'
xcodebuild build -project ../MMMDKitDemos/macOSDemo/MMMDKitMacDemo.xcodeproj -scheme MMMDKitMacDemo -destination 'platform=macOS'
```

## 项目状态

当前仓库已经包含模块协议、UIKit/AppKit 渲染入口、iOS/macOS demo 和基础单元测试。路线图见 `Docs/Roadmap.md` 和 `Docs/TODO.md`。
