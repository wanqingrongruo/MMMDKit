# 自定义指南

MMMDKit 的核心目标是让每个主要子系统都可以被替换，也可以被单独使用。

## 替换 Parser

```swift
var configuration = MarkdownConfiguration()
configuration.parser = MyMarkdownParser()
```

当你不想使用 cmark-gfm，或者服务端已经返回结构化 Markdown AST 时，可以替换 parser。

## 添加插件

```swift
configuration.plugins = [
    MentionPlugin(),
    MermaidPlugin(),
    ProductCardPlugin()
]
```

插件会在 layout 和 render 之前转换 `MarkdownDocument`。

## 替换代码高亮

```swift
configuration.highlighter = MyCodeHighlighter()
```

高亮模块可以被代码块、编辑器或日志查看器独立使用。

## 替换数学公式渲染

```swift
configuration.mathRenderer = MyMathRenderer()
```

生产实现可以包装 KaTeX、MathJax、iosMath 或自研原生引擎。

## 替换 HTML 渲染

```swift
configuration.htmlRenderer = MyHTMLRenderer()
```

默认策略应该让简单 HTML 保持原生渲染，把复杂 HTML 交给 fallback block。

## 替换 Block 渲染

```swift
configuration.blockRenderers[.code] = MyCodeBlockRenderer()
configuration.blockRenderers[.table] = MyTableBlockRenderer()
```

这是业务侧定制 UI 的主要入口。

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
    colors: .default,
    spacing: .default
)
```

主题值应该保持语义化，方便处理动态字体、暗黑模式和平台差异。
