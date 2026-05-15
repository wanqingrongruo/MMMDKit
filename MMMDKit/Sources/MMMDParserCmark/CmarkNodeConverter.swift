import Foundation
import MMMDCore

enum CmarkNodeConverter {
    static func document(from rootNode: CmarkNode, source: String) -> MarkdownDocument {
        let converted = convertedBlocks(from: rootNode.children)
        return MarkdownDocument(
            blocks: converted.map(\.block),
            source: source,
            blockSourceRanges: converted.map(\.sourceRange)
        )
    }

    static func blocks(from nodes: [CmarkNode]) -> [MarkdownBlock] {
        convertedBlocks(from: nodes).map(\.block)
    }

    private static func convertedBlocks(from nodes: [CmarkNode]) -> [ConvertedBlock] {
        nodes.compactMap { node in
            guard let block = block(from: node) else {
                return nil
            }
            return ConvertedBlock(block: block, sourceRange: node.sourceRange)
        }
    }

    private static func block(from node: CmarkNode) -> MarkdownBlock? {
        switch node.type {
        case .document:
            return nil
        case .paragraph:
            let inlineNodes = inlines(from: node.children)
            if inlineNodes.count == 1, case .image(let alt, let url) = inlineNodes[0] {
                return .image(.init(alt: alt, url: url))
            }
            return .paragraph(.init(inlineNodes))
        case .heading(let level):
            return .heading(level: level, content: .init(inlines(from: node.children)))
        case .blockquote:
            return .blockquote(blocks(from: node.children))
        case .list(let style):
            return .list(.init(style: listStyle(from: style), items: listItems(from: node.children)))
        case .table:
            return table(from: node)
        case .mathBlock(let latex):
            return .math(.init(latex: latex, displayMode: true))
        case .codeBlock(let language, let content):
            return .code(.init(language: language, content: content))
        case .thematicBreak:
            return .thematicBreak
        case .tableRow, .tableCell, .listItem, .text, .inlineMath, .emphasis, .strong, .link, .image:
            return nil
        }
    }

    private static func table(from node: CmarkNode) -> MarkdownBlock {
        let rows = node.children.compactMap { rowNode -> (isHeader: Bool, cells: [InlineContent])? in
            guard case .tableRow(let isHeader) = rowNode.type else {
                return nil
            }
            return (
                isHeader,
                rowNode.children.compactMap { cellNode in
                    guard case .tableCell = cellNode.type else {
                        return nil
                    }
                    return InlineContent(inlines(from: cellNode.children))
                }
            )
        }

        let header = rows.first(where: \.isHeader)?.cells ?? []
        let body = rows.filter { !$0.isHeader }.map(\.cells)
        return .table(.init(header: header, rows: body))
    }

    private static func listStyle(from style: CmarkListStyle) -> ListBlock.Style {
        switch style {
        case .ordered(let start):
            return .ordered(start: start)
        case .unordered:
            return .unordered
        }
    }

    private static func listItems(from nodes: [CmarkNode]) -> [ListItem] {
        nodes.compactMap { node in
            guard case .listItem = node.type else {
                return nil
            }
            return ListItem(blocks: blocks(from: node.children))
        }
    }

    private static func inlines(from nodes: [CmarkNode]) -> [InlineNode] {
        nodes.compactMap { node in
            switch node.type {
            case .text(let value):
                return .text(value)
            case .inlineMath(let latex):
                return .math(latex)
            case .emphasis:
                return .emphasis(inlines(from: node.children))
            case .strong:
                return .strong(inlines(from: node.children))
            case .link(let destination):
                return .link(text: inlines(from: node.children), url: destination)
            case .image(let alt, let url):
                return .image(alt: alt, url: url)
            default:
                return nil
            }
        }
    }
}

private struct ConvertedBlock {
    var block: MarkdownBlock
    var sourceRange: SourceRange?
}
