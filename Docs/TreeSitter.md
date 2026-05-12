# Tree-sitter 集成指南

MMMDKit 默认使用基于正则和关键字匹配的轻量级代码高亮（`KeywordCodeHighlighter` / `PlainCodeHighlighter`），以保持框架的极小体积。

在生产环境中，如果你需要像 IDE 一样精准的语法高亮，我们推荐接入 [Tree-sitter](https://tree-sitter.github.io/tree-sitter/)。

## 为什么是可选的？
Tree-sitter 需要为每种支持的语言编译对应的 C 代码库（如 `tree-sitter-swift`, `tree-sitter-python` 等），这会显著增加 App 的包体积。因此，MMMDKit 将其作为可选扩展，通过 `CodeHighlighter` 协议暴露接入点。

## 接入步骤

1. 引入 Tree-sitter Swift 绑定库（如 [SwiftTreeSitter](https://github.com/ChimeHQ/SwiftTreeSitter)）。
2. 实现 `CodeHighlighter` 协议。
3. 在 `MarkdownConfiguration` 中注入。

### 代码示例

```swift
import MMMDCore
import SwiftTreeSitter

public final class TreeSitterHighlighter: CodeHighlighter {
    public init() {}
    
    public func highlight(code: String, language: String?, theme: CodeTheme) async throws -> HighlightResult {
        // 1. 根据 language 获取对应的 Tree-sitter Language 实例
        // 2. 解析代码生成 Tree
        // 3. 遍历 Tree 的 Node，结合 theme.tokenColors 映射颜色
        // 4. 返回包含 HighlightToken 的 HighlightResult
        
        // 伪代码：
        // let tree = parser.parse(code)
        // let tokens = mapTreeToTokens(tree, theme: theme)
        // return HighlightResult(tokens: tokens)
        
        return HighlightResult(tokens: [])
    }
}

// 在业务侧使用：
var configuration = MarkdownConfiguration()
configuration.codeHighlighter = TreeSitterHighlighter()
```
