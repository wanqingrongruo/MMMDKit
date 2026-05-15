import Foundation

public enum MarkdownTextExtractor {
    public static func plainText(from document: MarkdownDocument) -> String {
        document.blocks.map(plainText(from:)).joined(separator: "\n")
    }

    public static func plainText(from block: MarkdownBlock) -> String {
        switch block {
        case .paragraph(let content), .heading(_, let content):
            return plainText(from: content)
        case .blockquote(let blocks):
            return blocks.map(plainText(from:)).joined(separator: "\n")
        case .list(let list):
            return list.items
                .map { item in item.blocks.map(plainText(from:)).joined(separator: "\n") }
                .joined(separator: "\n")
        case .code(let code):
            return code.content
        case .table(let table):
            let header = table.header.map(plainText(from:)).joined(separator: "\t")
            let rows = table.rows.map { $0.map(plainText(from:)).joined(separator: "\t") }
            return ([header] + rows).joined(separator: "\n")
        case .math(let math):
            return math.latex
        case .html(let html):
            return html.html
        case .image(let image):
            return image.alt
        case .thematicBreak:
            return "---"
        case .custom(let custom):
            return custom.payload
        }
    }

    public static func plainText(from content: InlineContent) -> String {
        content.nodes.map(plainText(from:)).joined()
    }

    public static func plainText(from node: InlineNode) -> String {
        switch node {
        case .text(let text), .code(let text), .math(let text), .html(let text):
            return text
        case .emphasis(let nodes), .strong(let nodes):
            return nodes.map(plainText(from:)).joined()
        case .link(let text, _):
            return text.map(plainText(from:)).joined()
        case .image(let alt, _):
            return alt
        case .softBreak, .lineBreak:
            return "\n"
        case .custom(_, let payload):
            return payload
        }
    }
}
