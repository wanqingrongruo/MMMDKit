import Foundation

/// Markdown 文档的根模型。
///
/// 解析器会把原始 Markdown 文本转换为 `MarkdownDocument`，渲染层只依赖该结构绘制内容。
public struct MarkdownDocument: Equatable, Sendable {
    /// 文档中的块级节点，顺序与源文本一致。
    public var blocks: [MarkdownBlock]
    /// 原始 Markdown 文本，主要用于复制、缓存 key 和调试。
    public var source: String
    /// 每个块在原始文本中的位置；当解析器无法提供时，对应元素为 `nil`。
    public var blockSourceRanges: [SourceRange?]

    public init(blocks: [MarkdownBlock], source: String = "", blockSourceRanges: [SourceRange?]? = nil) {
        self.blocks = blocks
        self.source = source
        self.blockSourceRanges = blockSourceRanges ?? Array(repeating: nil, count: blocks.count)
    }
}

/// Markdown 节点在源文本中的行列范围。
public struct SourceRange: Equatable, Sendable {
    public var startLine: Int
    public var startColumn: Int
    public var endLine: Int
    public var endColumn: Int

    public init(startLine: Int, startColumn: Int, endLine: Int, endColumn: Int) {
        self.startLine = startLine
        self.startColumn = startColumn
        self.endLine = endLine
        self.endColumn = endColumn
    }
}

/// Markdown 的块级节点类型。
///
/// 文档渲染的主体由块级节点组成，例如段落、标题、列表、代码块、表格和公式块。
public enum MarkdownBlock: Equatable, Sendable {
    case paragraph(InlineContent)
    case heading(level: Int, content: InlineContent)
    case blockquote([MarkdownBlock])
    case list(ListBlock)
    case code(CodeBlock)
    case table(TableBlock)
    case math(MathBlock)
    case html(HTMLBlock)
    case image(ImageBlock)
    case thematicBreak
    case custom(CustomBlock)
}

/// 块级节点的稳定分类，用于注册自定义渲染器和做缓存分组。
public enum MarkdownBlockKind: String, Hashable, Sendable {
    case paragraph
    case heading
    case blockquote
    case list
    case code
    case table
    case math
    case html
    case image
    case thematicBreak
    case custom
}

public extension MarkdownBlock {
    var kind: MarkdownBlockKind {
        switch self {
        case .paragraph: return .paragraph
        case .heading: return .heading
        case .blockquote: return .blockquote
        case .list: return .list
        case .code: return .code
        case .table: return .table
        case .math: return .math
        case .html: return .html
        case .image: return .image
        case .thematicBreak: return .thematicBreak
        case .custom: return .custom
        }
    }
}

/// Markdown 的行内内容容器。
///
/// 段落、标题、表格单元格等文本区域都由若干 `InlineNode` 组成。
public struct InlineContent: Equatable, Sendable {
    public var nodes: [InlineNode]

    public init(_ nodes: [InlineNode]) {
        self.nodes = nodes
    }

    public init(text: String) {
        self.nodes = [.text(text)]
    }
}

/// Markdown 的行内节点类型。
public enum InlineNode: Equatable, Sendable {
    case text(String)
    case emphasis([InlineNode])
    case strong([InlineNode])
    case code(String)
    case link(text: [InlineNode], url: URL?)
    case image(alt: String, url: URL?)
    case softBreak
    case lineBreak
    case math(String)
    case html(String)
    case custom(name: String, payload: String)
}

/// 行内节点的稳定分类，用于注册自定义行内渲染器。
public enum InlineNodeKind: String, Hashable, Sendable {
    case text
    case emphasis
    case strong
    case code
    case link
    case image
    case softBreak
    case lineBreak
    case math
    case html
    case custom
}

public extension InlineNode {
    var kind: InlineNodeKind {
        switch self {
        case .text: return .text
        case .emphasis: return .emphasis
        case .strong: return .strong
        case .code: return .code
        case .link: return .link
        case .image: return .image
        case .softBreak: return .softBreak
        case .lineBreak: return .lineBreak
        case .math: return .math
        case .html: return .html
        case .custom: return .custom
        }
    }
}

/// 列表块模型，支持有序、无序和任务列表。
public struct ListBlock: Equatable, Sendable {
    /// 列表样式。
    public enum Style: Equatable, Sendable {
        /// 有序列表，`start` 表示起始序号。
        case ordered(start: Int)
        /// 无序列表。
        case unordered
        /// 任务列表，勾选状态保存在 `ListItem.isChecked`。
        case task
    }

    public var style: Style
    public var items: [ListItem]

    public init(style: Style, items: [ListItem]) {
        self.style = style
        self.items = items
    }
}

/// 单个列表项。
public struct ListItem: Equatable, Sendable {
    public var blocks: [MarkdownBlock]
    public var isChecked: Bool?

    public init(blocks: [MarkdownBlock], isChecked: Bool? = nil) {
        self.blocks = blocks
        self.isChecked = isChecked
    }
}

/// 围栏代码块模型。
public struct CodeBlock: Equatable, Sendable {
    /// 代码语言标识，例如 `swift`、`json`。
    public var language: String?
    /// 代码块正文，不包含围栏标记。
    public var content: String
    /// 语言标识后的额外元信息。
    public var metadata: String?

    public init(language: String? = nil, content: String, metadata: String? = nil) {
        self.language = language
        self.content = content
        self.metadata = metadata
    }
}

/// 表格块模型。
public struct TableBlock: Equatable, Sendable {
    public var header: [InlineContent]
    public var rows: [[InlineContent]]

    public init(header: [InlineContent], rows: [[InlineContent]]) {
        self.header = header
        self.rows = rows
    }
}

/// 块级数学公式模型。
public struct MathBlock: Equatable, Sendable {
    /// LaTeX 源码。
    public var latex: String
    /// 是否按 display math 模式渲染。
    public var displayMode: Bool

    public init(latex: String, displayMode: Bool) {
        self.latex = latex
        self.displayMode = displayMode
    }
}

/// HTML 块模型。
public struct HTMLBlock: Equatable, Sendable {
    public var html: String

    public init(html: String) {
        self.html = html
    }
}

/// 图片块模型。
public struct ImageBlock: Equatable, Sendable {
    /// 图片替代文本。
    public var alt: String
    /// 图片地址。
    public var url: URL?

    public init(alt: String, url: URL?) {
        self.alt = alt
        self.url = url
    }
}

/// 自定义块模型，用于承载业务扩展节点。
public struct CustomBlock: Equatable, Sendable {
    public var name: String
    public var payload: String

    public init(name: String, payload: String) {
        self.name = name
        self.payload = payload
    }
}
