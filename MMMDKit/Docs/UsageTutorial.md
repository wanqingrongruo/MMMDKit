# MMMDKit 使用与配置教程

MMMDKit 是一个面向 Apple 平台的模块化原生 Markdown 渲染框架。它把 Markdown 解析、流式处理、代码高亮、公式渲染、HTML 策略和 UIKit/AppKit 展示拆成独立模块，方便业务按需组合。

本教程覆盖从安装到静态渲染、AI 流式输出、主题配置和扩展点的常见接入路径。

---

## 1. 选择模块

### 1.1 常用模块

- `MMMDCore`：文档模型、协议、主题、交互回调和配置项。
- `MMMDParserCmark`：默认 Markdown 解析器，输出 `MarkdownDocument`。
- `MMMDStreaming`：流式文本 buffer、稳定块判断、节流更新。
- `MMMDHighlighter`：默认代码高亮实现，也提供 `CodeHighlighter` 协议。
- `MMMDMath`：公式渲染协议和纯文本 fallback。
- `MMMDHTML`：HTML 清洗和渲染能力判断。
- `MMMDUIKit`：iOS/iPadOS 的 `MarkdownView`。
- `MMMDAppKit`：macOS 的 `MarkdownNSView`。

### 1.2 推荐组合

iOS/iPadOS 应用：

```swift
import MMMDCore
import MMMDParserCmark
import MMMDUIKit
```

macOS 应用：

```swift
import MMMDCore
import MMMDParserCmark
import MMMDAppKit
```

如果只需要无 UI 的流式解析，例如在 ViewModel 或服务层预处理，可以只引入：

```swift
import MMMDCore
import MMMDParserCmark
import MMMDStreaming
```

---

## 2. 安装

### 2.1 Swift Package Manager

在 Xcode 中添加 Package，或在 `Package.swift` 中声明：

```swift
dependencies: [
    .package(url: "git@github.com:wanqingrongruo/MMMDKit.git", from: "0.1.0")
]
```

iOS target 常用 product：

```swift
.product(name: "MMMDParserCmark", package: "MMMDKit")
.product(name: "MMMDUIKit", package: "MMMDKit")
```

macOS target 常用 product：

```swift
.product(name: "MMMDParserCmark", package: "MMMDKit")
.product(name: "MMMDAppKit", package: "MMMDKit")
```

如果需要显式使用流式或高亮模块，也可以加入：

```swift
.product(name: "MMMDStreaming", package: "MMMDKit")
.product(name: "MMMDHighlighter", package: "MMMDKit")
```

通过 SPM 引入 `MMMDUIKit` / `MMMDAppKit` 时，会传递引入 SwiftMath，块级公式默认使用原生公式排版。

### 2.2 CocoaPods

```ruby
pod "MMMDCore"
pod "MMMDParserCmark"
pod "MMMDStreaming"
pod "MMMDHighlighter"
pod "MMMDUIKit"   # iOS/iPadOS
# pod "MMMDAppKit" # macOS
```

CocoaPods 当前不会自动引入 SwiftMath，所以公式块会 fallback 为 LaTeX 文本。需要真实公式排版时，请自行实现 `MathRenderer` 并注入到 `MarkdownConfiguration.mathRenderer`。

---

## 3. UIKit 静态渲染

### 3.1 创建视图

```swift
import UIKit
import MMMDCore
import MMMDParserCmark
import MMMDHighlighter
import MMMDUIKit

final class MarkdownViewController: UIViewController {
    private let markdownView = MarkdownView()
    private let parser = CmarkMarkdownParser()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        markdownView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(markdownView)
        NSLayoutConstraint.activate([
            markdownView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            markdownView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            markdownView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            markdownView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        markdownView.configuration = makeConfiguration()
        renderMarkdown()
    }

    private func makeConfiguration() -> MarkdownConfiguration {
        MarkdownConfiguration(
            actions: .init(
                onLinkTap: { url in
                    UIApplication.shared.open(url)
                },
                onCopyCode: { code, language in
                    UIPasteboard.general.string = code
                    print("已复制代码，语言：\(language ?? "unknown")")
                }
            ),
            codeHighlighter: KeywordCodeHighlighter(),
            codeBlockMaximumWidth: 640
        )
    }

    private func renderMarkdown() {
        let source = """
        # MMMDKit

        这是一段 **Markdown**，包含代码块：

        ```swift
        let message = "Hello"
        print(message)
        ```
        """

        do {
            let document = try parser.parse(source)
            markdownView.render(document)
        } catch {
            assertionFailure("Markdown 解析失败：\(error)")
        }
    }
}
```

### 3.2 更新已有内容

当你拿到一份完整 Markdown 文本时，重新解析并调用 `render(_:)` 即可：

```swift
let document = try parser.parse(newMarkdown)
markdownView.render(document)
```

`render(_:)` 会应用 `configuration.plugins`，并重建内部视图层级。建议在内容确实变化时调用，避免不必要的 UI 重建。

---

## 4. AI 流式渲染

### 4.1 直接使用视图内置流式 API

对于 ChatGPT、LLM SSE、WebSocket 等不断返回 delta 文本的场景，推荐使用视图内置 API：

```swift
markdownView.configuration = MarkdownConfiguration(codeHighlighter: KeywordCodeHighlighter())
markdownView.startStreaming(parser: CmarkMarkdownParser(), updateInterval: 0.08)

for await delta in aiTextStream {
    markdownView.appendStreamingText(delta)
}

markdownView.finishStreaming()
```

关键点：

- `appendStreamingText(_:)` 可以持续追加新文本，不需要业务自己维护完整字符串。
- `updateInterval` 控制 UI 刷新节流，默认 `0.08` 秒，适合多数打字机效果。
- 流式阶段最后一个块通常不稳定，库会避免对尾部代码块反复高亮，减少闪烁。
- `finishStreaming()` 会触发最终渲染，此时所有块都视为稳定。

### 4.2 重置流式内容

开始一条新的回答前，可以重置当前流：

```swift
markdownView.resetStreaming()
markdownView.startStreaming(parser: CmarkMarkdownParser())
```

如果你每次都调用新的 `startStreaming(...)`，旧的会话会被视图替换。

### 4.3 获取每次 diff

如果业务需要在每次文档更新时同步滚动、计算高度或更新外部状态，可以使用 `onUpdate`：

```swift
markdownView.startStreaming(
    parser: CmarkMarkdownParser(),
    updateInterval: 0.08
) { diff in
    print("当前块数量：\(diff.document.blocks.count)")
    print("稳定块数量：\(diff.stableBlockCount)")
}
```

`stableBlockCount` 表示前多少个块已经稳定。业务侧做虚拟列表、缓存布局或局部刷新时，可以优先复用这些稳定块。

### 4.4 无 UI 的流式解析

如果你在 ViewModel 层处理 Markdown，可以直接使用 `StreamingMarkdownSession`：

```swift
let session = StreamingMarkdownSession(
    parser: CmarkMarkdownParser(),
    updateInterval: 0.08,
    deliveryQueue: .main
)

session.onUpdate = { diff in
    // diff.document 是当前完整 MarkdownDocument
    // diff.phase == .finished 时，所有块都稳定
}

session.append("## 标题\n\n")
session.append("正文第一段")
session.finish()
```

底层还有 `StreamingMarkdownProcessor`，它不做线程切换和节流，适合测试、基准性能或你自己管理调度队列的场景。

---

## 5. macOS 接入

macOS 使用 `MarkdownNSView`，API 与 UIKit 版本保持一致：

```swift
import AppKit
import MMMDCore
import MMMDParserCmark
import MMMDHighlighter
import MMMDAppKit

final class MarkdownViewController: NSViewController {
    private let markdownView = MarkdownNSView()

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        markdownView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(markdownView)
        NSLayoutConstraint.activate([
            markdownView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            markdownView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            markdownView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            markdownView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])

        markdownView.configuration = MarkdownConfiguration(codeHighlighter: KeywordCodeHighlighter())
        markdownView.render(try! CmarkMarkdownParser().parse("# macOS\n\nHello MMMDKit"))
    }
}
```

---

## 6. SwiftUI 包装

MMMDKit 当前提供 UIKit/AppKit 视图。SwiftUI 中可以用 `UIViewRepresentable` 或 `NSViewRepresentable` 包装。

### 6.1 iOS SwiftUI

```swift
import SwiftUI
import MMMDCore
import MMMDParserCmark
import MMMDUIKit

struct MarkdownRepresentable: UIViewRepresentable {
    let markdown: String
    var configuration = MarkdownConfiguration()

    func makeUIView(context: Context) -> MarkdownView {
        let view = MarkdownView()
        view.configuration = configuration
        return view
    }

    func updateUIView(_ uiView: MarkdownView, context: Context) {
        guard let document = try? CmarkMarkdownParser().parse(markdown) else { return }
        uiView.configuration = configuration
        uiView.render(document)
    }
}
```

### 6.2 macOS SwiftUI

```swift
import SwiftUI
import MMMDCore
import MMMDParserCmark
import MMMDAppKit

struct MarkdownRepresentable: NSViewRepresentable {
    let markdown: String
    var configuration = MarkdownConfiguration()

    func makeNSView(context: Context) -> MarkdownNSView {
        let view = MarkdownNSView()
        view.configuration = configuration
        return view
    }

    func updateNSView(_ nsView: MarkdownNSView, context: Context) {
        guard let document = try? CmarkMarkdownParser().parse(markdown) else { return }
        nsView.configuration = configuration
        nsView.render(document)
    }
}
```

---

## 7. 配置项

### 7.1 交互回调

`MarkdownActions` 集中管理用户交互：

```swift
let actions = MarkdownActions(
    onLinkTap: { url in
        UIApplication.shared.open(url)
    },
    onCopyCode: { code, language in
        UIPasteboard.general.string = code
    },
    onCopyTable: { tableText in
        UIPasteboard.general.string = tableText
    },
    onImageTap: { imageBlock in
        print("点击图片：\(imageBlock.url?.absoluteString ?? "")")
    }
)

var configuration = MarkdownConfiguration(actions: actions)
```

macOS 中把 `UIApplication` / `UIPasteboard` 替换为 `NSWorkspace` / `NSPasteboard` 即可。

### 7.2 工具栏按钮

代码块和表格顶部工具栏可控制复制、下载和展开按钮：

```swift
let toolbarOptions = ToolbarOptions(
    showsCopy: true,
    showsDownload: false,
    showsExpand: false
)

let configuration = MarkdownConfiguration(toolbarOptions: toolbarOptions)
```

### 7.3 主题

主题使用平台无关的字符串 token，渲染层会把它们映射为系统颜色和字体：

```swift
let theme = MarkdownTheme(
    typography: .init(
        body: .init(textStyle: "body", pointSize: 16, weight: "regular"),
        code: .init(textStyle: "body", pointSize: 14, weight: "regular", design: "monospaced"),
        heading1: .init(textStyle: "title2", pointSize: 22, weight: "medium"),
        heading2: .init(textStyle: "title3", pointSize: 20, weight: "medium")
    ),
    colors: .init(
        text: "label",
        secondaryText: "secondaryLabel",
        link: "systemBlue",
        codeBackground: "secondarySystemBackground",
        tableBorder: "separator"
    ),
    spacing: .init(
        blockSpacing: 14,
        paragraphSpacing: 10,
        listIndent: 20,
        codePadding: 12
    ),
    codeTheme: .github
)

let configuration = MarkdownConfiguration(theme: theme)
```

### 7.4 代码高亮

内置两种高亮器：

- `PlainCodeHighlighter`：不做语法分析，只返回纯文本 token。
- `KeywordCodeHighlighter`：轻量识别 Swift 关键字、字符串、数字和注释。

```swift
let configuration = MarkdownConfiguration(
    codeHighlighter: KeywordCodeHighlighter()
)
```

自定义高亮器实现 `CodeHighlighter`：

```swift
struct MyCodeHighlighter: CodeHighlighter {
    func highlight(code: String, language: String?, theme: CodeTheme) async throws -> HighlightResult {
        HighlightResult(language: language, tokens: [
            .init(text: code, scope: nil)
        ])
    }
}
```

渲染层会根据 `HighlightToken.scope` 和 `CodeTheme.tokenStyles` 生成最终 attributed string。

### 7.5 图片加载

实现 `ImageLoader` 后注入配置：

```swift
struct NetworkImageLoader: ImageLoader {
    func loadImageData(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}

let configuration = MarkdownConfiguration(imageLoader: NetworkImageLoader())
```

### 7.6 公式渲染

SPM 引入 UI 模块时，默认会获得 SwiftMath 公式排版。若你需要自定义公式渲染器，实现 `MathRenderer`：

```swift
struct PlainMathRenderer: MathRenderer {
    func render(latex: String, displayMode: Bool, environment: MathEnvironment) async throws -> MathRenderResult {
        MathRenderResult(representation: .plainText(latex), accessibilityLabel: latex)
    }
}

let configuration = MarkdownConfiguration(mathRenderer: PlainMathRenderer())
```

### 7.7 插件

插件用于在渲染前改写 AST：

```swift
struct FooterPlugin: MarkdownPlugin {
    func transform(document: MarkdownDocument, context: PluginContext) throws -> MarkdownDocument {
        var document = document
        document.blocks.append(.paragraph(.init(text: "由 MMMDKit 渲染")))
        return document
    }
}

let configuration = MarkdownConfiguration(plugins: [FooterPlugin()])
```

---

## 8. 常见建议

- 对完整静态内容使用 `render(_:)`；对 AI delta 使用 `startStreaming(...)` + `appendStreamingText(_:)`。
- 流式刷新频率不宜过高，`updateInterval` 建议从 `0.06` 到 `0.12` 秒之间调整。
- 代码块较多时建议提供可缓存的高亮器；库内会对稳定代码块缓存渲染结果。
- 图片加载器应自行处理缓存、鉴权和错误占位。
- HTML 清洗器只是基础防护，不应替代服务端安全策略。
- `MarkdownConfiguration` 应在渲染前设置；修改配置后需要重新 `render(_:)` 才能让已有内容使用新配置。

---

## 9. 调试与验证

库目录位于仓库的 `MMMDKit/`。常用验证命令：

```bash
cd MMMDKit
swift test

cd ..
xcodebuild build -project MMMDKitDemos/iOSDemo/MMMDKitiOSDemo.xcodeproj -scheme MMMDKitiOSDemo -destination 'generic/platform=iOS Simulator'
xcodebuild build -project MMMDKitDemos/macOSDemo/MMMDKitMacDemo.xcodeproj -scheme MMMDKitMacDemo -destination 'platform=macOS'
```

如果 Xcode 出现模块找不到或旧 API 报错，优先执行 `File > Packages > Reset Package Caches`，再重新打开工程。
