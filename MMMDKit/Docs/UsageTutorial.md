# MMMDKit 使用与配置教程

MMMDKit 是一个面向 Apple 平台的模块化原生 Markdown 渲染框架。本教程将带你从引入库开始，逐步了解如何展示 Markdown、配置样式主题以及进行高阶功能自定义。

---

## 1. 引入库

MMMDKit 支持 **CocoaPods** 和 **Swift Package Manager (SPM)** 两种主流方式。它被设计为多模块架构，你可以按需引入所需的模块。

### 核心模块概览
* **`MMMDCore`**: 基础模型（AST、配置、主题、协议等），无 UI 依赖。
* **`MMMDParserCmark`**: C 语言 cmark-gfm 解析器的适配层，将 Markdown 文本解析为 AST。
* **`MMMDHighlighter`**: 包含基本的纯文本代码高亮器，或你可基于此模块实现 Tree-sitter 等高阶高亮。
* **`MMMDUIKit`**: iOS/iPadOS 原生渲染容器 (`MarkdownView`)。
* **`MMMDAppKit`**: macOS 原生渲染容器 (`MarkdownView`)。

### 方式 A: Swift Package Manager
在 Xcode 项目中添加 Package 依赖：
```swift
dependencies: [
    .package(url: "git@github.com:wanqingrongruo/MMMDKit.git", from: "0.1.0")
]
```
在 target 中选择你需要引入的 Product。如果你是在 iOS 项目中，通常需要选中 `MMMDCore`, `MMMDParserCmark`, `MMMDUIKit` 以及（可选的）`MMMDHighlighter`。

> 推荐：如果你需要开箱即用的原生数学公式渲染，请优先使用 SPM。`MMMDUIKit` / `MMMDAppKit` 会通过 SPM 传递引入 SwiftMath，用于渲染 `$$...$$` block math。

### 方式 B: CocoaPods
在 `Podfile` 中添加：
```ruby
# 引入完整套件：
pod "MMMDKit"

# 或者按模块引入（推荐）：
pod "MMMDCore"
pod "MMMDParserCmark"
pod "MMMDHighlighter"
# iOS 引入 UIKit 版，macOS 引入 AppKit 版：
pod "MMMDUIKit" 
# pod "MMMDAppKit" 
```

#### CocoaPods 与公式渲染差异

CocoaPods 可以正常集成 MMMDKit 的各个模块，但当前原生公式排版依赖的 `mgriebling/SwiftMath` 主要通过 Swift Package Manager 分发。  
因此通过 CocoaPods 引入 `MMMDUIKit` / `MMMDAppKit` 时：

- 不会自动获得 SwiftMath 原生公式渲染。
- `MathBlockView` 会自动 fallback 到 LaTeX 文本展示，避免编译失败或空白。
- 如果需要 CocoaPods 下也渲染真实公式，需要业务侧自行提供 `MarkdownConfiguration.mathRenderer`，或在工程中 vendoring 其他 CocoaPods 可用的公式渲染实现。

SPM 和 CocoaPods 的差异只影响默认公式渲染能力，Markdown 解析、文本、引用、代码块、表格、分割线等能力不受影响。

---

## 2. 快速使用

MMMDKit 的主要视图是 `MarkdownView`。使用步骤通常分为两步：**解析文本** 和 **渲染视图**。

### 2.1 渲染静态 Markdown
在你的 ViewController (或 SwiftUI 的 UIViewRepresentable) 中：

```swift
import MMMDCore
import MMMDParserCmark
import MMMDUIKit // macOS 则 import MMMDAppKit

// 1. 准备解析器
let parser = CmarkMarkdownParser()

// 2. 初始化 MarkdownView
let markdownView = MarkdownView(configuration: MarkdownConfiguration())
markdownView.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(markdownView)

// (此处省略 Auto Layout 约束代码，需自行添加宽高或边距约束)

// 3. 解析文本并设置给视图
let markdownText = "# Hello\nThis is **MMMDKit**."
if let document = try? parser.parse(markdownText) {
    markdownView.document = document
}
```

### 2.2 流式更新 (Streaming)
如果你的数据来源于 AI 接口的流式输出，你只需持续解析新的拼接文本，并调用 `updateDocument`，视图会在内部进行 diff 并平滑滚动：

```swift
// 当收到新的 chunk 时：
currentMarkdownText += newChunk
if let newDocument = try? parser.parse(currentMarkdownText) {
    // 使用 updateDocument 而不是直接赋值，以获得更平滑的刷新体验
    markdownView.updateDocument(newDocument)
}
```

---

## 3. 详细配置 (Configuration & Theme)

所有的渲染配置都通过 `MarkdownConfiguration` 传入 `MarkdownView` 的初始化方法。一旦初始化，配置就不能被更改，如果需要换肤则需新建一个 `MarkdownView` 实例。

### 3.1 监听交互事件 (Actions)
你可以通过 `MarkdownActions` 配置用户交互的回调，如点击链接、点击代码块右上角的复制按钮等：

```swift
var actions = MarkdownActions()

// 链接点击回调
actions.onLinkTap = { url in
    UIApplication.shared.open(url)
}

// 代码块复制回调
actions.onCopyCode = { codeText in
    UIPasteboard.general.string = codeText
    print("代码已复制！")
    // 这里可以结合你的业务展示 Toast
}

// （类似地，还有 onCopyTable, onDownloadCode, onExpandCode 等等）
```

### 3.2 工具栏配置 (ToolbarOptions)
工具栏出现在代码块和表格的上方（包含标题、复制等按钮）。可以通过 `toolbarOptions` 来控制按钮的显示：

```swift
var toolbarOptions = ToolbarOptions()
toolbarOptions.showsCopy = true     // 默认 true
toolbarOptions.showsDownload = false // 是否显示下载按钮
toolbarOptions.showsExpand = false   // 是否显示全屏展开按钮
toolbarOptions.isStickyHeaderEnabled = true // 代码块顶部工具栏是否吸顶滚动（支持长代码块）
```

### 3.3 修改样式与主题 (MarkdownTheme)
MMMDKit 提供了细粒度的样式控制方案。`MarkdownTheme` 包含四大模块：字体(`typography`)、颜色(`colors`)、间距(`spacing`) 和 代码主题(`codeTheme`)。

下面是一个仿“豆包 App”风格的主题配置示例：

```swift
import UIKit // macOS 使用 AppKit

var theme = MarkdownTheme()

// 1. 修改颜色 (支持亮暗色动态变化)
theme.colors.text = UIColor.label
theme.colors.link = UIColor.systemBlue
theme.colors.codeBackground = UIColor.secondarySystemBackground
theme.colors.tableBorder = UIColor.systemGray4
theme.colors.tableHeaderBackground = UIColor.tertiarySystemGroupedBackground
theme.colors.blockquoteBorder = UIColor.systemGray3

// 2. 修改字体
theme.typography.body = UIFont.systemFont(ofSize: 16)
theme.typography.code = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
// 设置不同级别标题的字体大小
theme.typography.headingFonts = [
    1: UIFont.boldSystemFont(ofSize: 22),
    2: UIFont.boldSystemFont(ofSize: 20),
    3: UIFont.boldSystemFont(ofSize: 18)
]

// 3. 修改间距 (段落之间、列表缩进等)
theme.spacing.blockSpacing = 16.0
theme.spacing.paragraphSpacing = 12.0
theme.spacing.listIndent = 24.0

// 4. 应用配置
var configuration = MarkdownConfiguration(
    theme: theme,
    actions: actions,
    toolbarOptions: toolbarOptions,
    codeBlockMaximumWidth: 800 // 可选：限制代码块的最大宽度
)

let markdownView = MarkdownView(configuration: configuration)
```

---

## 4. 高阶定制 (Customization)

### 4.1 引入代码高亮支持 (CodeHighlighter)
默认情况下代码块渲染为等宽无颜色的纯文本。MMMDKit 允许你接入自定义的 `CodeHighlighter`（例如使用 Tree-sitter）。自带的 `MMMDHighlighter` 库提供了一个占位的 `PlainCodeHighlighter`。

```swift
import MMMDHighlighter

let highlighter = PlainCodeHighlighter()
var configuration = MarkdownConfiguration()
configuration.codeHighlighter = highlighter // 注入高亮器
```

高亮器需要遵循 `CodeHighlighter` 协议，接收源码并返回携带颜色的 `NSAttributedString`。

### 4.2 AST 插件预处理 (MarkdownPlugin)
如果你想在渲染前统一修改某些数据（例如将特定的文本替换成自定义节点，或给所有的外部链接加上特定参数），你可以编写 `MarkdownPlugin`：

```swift
struct MyCustomPlugin: MarkdownPlugin {
    func transform(document: MarkdownDocument, context: PluginContext) throws -> MarkdownDocument {
        // 遍历并修改 AST 节点
        // ...
        return document
    }
}

configuration.plugins = [MyCustomPlugin()]
```

### 4.3 扩展新的区块渲染器 (BlockRendererRegistry)
如果你的 Markdown 解析器解析出了自定义类型的 AST 块（比如名为 `.customWarning` 的块），你可以使用 registry 将其映射到你自定义的视图（如警告提示框）：

```swift
// 假设你自定义了一个 CustomWarningView: UIView / NSView
// 并且在 Registry 里注册它的名字
configuration.blockRendererRegistry.register(
    kind: .custom(name: "warning"), 
    rendererName: "CustomWarningView"
)
```
*（进阶提示：实际的自定义视图实例化还需要实现具体的 `BlockViewProvider` 并结合 `MarkdownView` 的组件缓存池，详见框架进阶文档。）*

---

## 小结

1. 使用 `CmarkMarkdownParser` 解析出 AST (`MarkdownDocument`)。
2. 使用 `MarkdownConfiguration` 声明回调 `actions`、控制外观 `theme`、绑定拓展能力 (`codeHighlighter` / `mathRenderer`)。
3. 创建 `MarkdownView(configuration: ...)`。
4. 给 `MarkdownView.document` 赋值或者使用 `updateDocument(_:)` 更新，完成渲染。

MMMDKit 设计十分灵活，所有 `MMMDCore` 中的协议均可被你的业务层对象实现，从而将框架完全融入你的原生应用架构中。
