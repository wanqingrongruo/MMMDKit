# 自定义指南

MMMDKit 的核心目标是让每个主要子系统都可以被替换，也可以被单独使用。

## 替换 Parser

Parser 不挂在 `MarkdownConfiguration` 上，而是在进入渲染前把 Markdown source 转成 `MarkdownDocument`。这让服务端 AST、自研 parser 和 `CmarkMarkdownParser` 都可以走同一条渲染管线。

```swift
struct PlainTextParser: MarkdownParser {
    func parse(_ source: String, options: ParseOptions) throws -> MarkdownDocument {
        MarkdownDocument(blocks: [.paragraph(.init(text: source))], source: source)
    }
}

let parser: MarkdownParser = PlainTextParser()
let document = try parser.parse("Hello", options: .init())
markdownView.render(document, configuration: configuration)
```

当你不想使用 cmark-gfm，或者服务端已经返回结构化 Markdown AST 时，可以替换 parser。

## 添加插件

```swift
configuration.plugins = [
    ProductCardPlugin()
]
```

插件会在 layout 和 render 之前转换 `MarkdownDocument`。

```swift
struct ProductCardPlugin: MarkdownPlugin {
    let name = "ProductCardPlugin"

    func transform(document: MarkdownDocument, context: PluginContext) throws -> MarkdownDocument {
        // 将约定语法转换成业务自定义 block。
        document
    }
}
```

## 替换代码高亮

```swift
configuration.codeHighlighter = MyCodeHighlighter()
```

高亮模块可以被代码块、编辑器或日志查看器独立使用。

## 替换数学公式渲染

```swift
configuration.mathRenderer = MyMathRenderer()
```

生产实现可以包装 KaTeX、MathJax、iosMath 或自研原生引擎。

## 替换 HTML 渲染

当前 HTML 渲染策略由 `HTMLBlockView` 和 `MMMDHTML` 的 sanitizer/capability 模块承担。生产侧如果需要完全替换 HTML 渲染，可以在上游 plugin 中把 HTML block 转成自定义 block，并通过 block renderer registry 交给业务 UI 处理。

## 替换 Block 渲染

```swift
var registry = BlockRendererRegistry()
registry.register(kind: .custom, rendererName: "ProductCardBlockRenderer")

configuration.blockRendererRegistry = registry
```

registry 只保存稳定的 renderer 名称和 block 类型映射。UIKit/AppKit 层可以据此把 `.custom` block 分发给业务 renderer。

## 替换 Inline 渲染

```swift
var registry = InlineRendererRegistry()
registry.register(kind: .custom, rendererName: "MentionInlineRenderer")

configuration.inlineRendererRegistry = registry
```

Inline registry 适合业务侧把 `.custom` inline node 映射到 mention、tag、票据等内联组件。

## 自定义行为

```swift
configuration.actions.onLinkTap = { url in
    // 使用业务路由打开链接。
}

configuration.actions.onCopyCode = { code, language in
    // 埋点或提供自定义复制行为。
}
```

## 自定义主题

```swift
configuration.theme = MarkdownTheme(
    typography: .default,
    colors: MarkdownColors(
        text: "label",
        secondaryText: "secondaryLabel",
        link: "systemMint",
        codeBackground: "secondarySystemBackground",
        tableBorder: "separator"
    ),
    spacing: MarkdownSpacing(
        blockSpacing: 16,
        paragraphSpacing: 10,
        listIndent: 28,
        codePadding: 14
    ),
    codeTheme: .default
)
```

主题值应该保持语义化，方便处理动态字体、暗黑模式和平台差异。

## 布局配置

```swift
configuration.codeBlockMaximumWidth = 760
```

代码块默认最大宽度为 `760`。设置为 `nil` 可以取消限制，让代码块始终撑满可用宽度。
