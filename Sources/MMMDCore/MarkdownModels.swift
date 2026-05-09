import Foundation

public struct MarkdownDocument: Equatable, Sendable {
    public var blocks: [MarkdownBlock]
    public var source: String

    public init(blocks: [MarkdownBlock], source: String = "") {
        self.blocks = blocks
        self.source = source
    }
}

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

public struct InlineContent: Equatable, Sendable {
    public var nodes: [InlineNode]

    public init(_ nodes: [InlineNode]) {
        self.nodes = nodes
    }

    public init(text: String) {
        self.nodes = [.text(text)]
    }
}

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

public struct ListBlock: Equatable, Sendable {
    public enum Style: Equatable, Sendable {
        case ordered(start: Int)
        case unordered
        case task
    }

    public var style: Style
    public var items: [ListItem]

    public init(style: Style, items: [ListItem]) {
        self.style = style
        self.items = items
    }
}

public struct ListItem: Equatable, Sendable {
    public var blocks: [MarkdownBlock]
    public var isChecked: Bool?

    public init(blocks: [MarkdownBlock], isChecked: Bool? = nil) {
        self.blocks = blocks
        self.isChecked = isChecked
    }
}

public struct CodeBlock: Equatable, Sendable {
    public var language: String?
    public var content: String
    public var metadata: String?

    public init(language: String? = nil, content: String, metadata: String? = nil) {
        self.language = language
        self.content = content
        self.metadata = metadata
    }
}

public struct TableBlock: Equatable, Sendable {
    public var header: [InlineContent]
    public var rows: [[InlineContent]]

    public init(header: [InlineContent], rows: [[InlineContent]]) {
        self.header = header
        self.rows = rows
    }
}

public struct MathBlock: Equatable, Sendable {
    public var latex: String
    public var displayMode: Bool

    public init(latex: String, displayMode: Bool) {
        self.latex = latex
        self.displayMode = displayMode
    }
}

public struct HTMLBlock: Equatable, Sendable {
    public var html: String

    public init(html: String) {
        self.html = html
    }
}

public struct ImageBlock: Equatable, Sendable {
    public var alt: String
    public var url: URL?

    public init(alt: String, url: URL?) {
        self.alt = alt
        self.url = url
    }
}

public struct CustomBlock: Equatable, Sendable {
    public var name: String
    public var payload: String

    public init(name: String, payload: String) {
        self.name = name
        self.payload = payload
    }
}
