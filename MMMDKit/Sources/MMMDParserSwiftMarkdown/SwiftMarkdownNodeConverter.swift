import Foundation
import Markdown
import MMMDCore

enum SwiftMarkdownNodeConverter {
    static func blocks(from children: MarkupChildren) -> [MarkdownBlock] {
        children.compactMap { block(from: $0) }
    }

    private static func block(from markup: Markup) -> MarkdownBlock? {
        switch markup {
        case let paragraph as Paragraph:
            let inlineNodes = inlines(from: paragraph.children)
            if inlineNodes.count == 1, case .image(let alt, let url) = inlineNodes[0] {
                return .image(.init(alt: alt, url: url))
            }
            return .paragraph(.init(inlineNodes))

        case let heading as Heading:
            return .heading(level: heading.level, content: .init(inlines(from: heading.children)))

        case let quote as BlockQuote:
            return .blockquote(blocks(from: quote.children))

        case let list as OrderedList:
            return .list(.init(style: .ordered(start: Int(list.startIndex)), items: listItems(from: list.children)))

        case let list as UnorderedList:
            let items = listItems(from: list.children)
            let style: ListBlock.Style = items.contains { $0.isChecked != nil } ? .task : .unordered
            return .list(.init(style: style, items: items))

        case let code as Markdown.CodeBlock:
            if code.language == "blockmath" || code.language == "math" {
                return .math(.init(latex: code.code.trimmingCharacters(in: .newlines), displayMode: true))
            }
            return .code(.init(language: code.language, content: code.code))

        case is ThematicBreak:
            return .thematicBreak

        case let table as Markdown.Table:
            return tableBlock(from: table)

        case let html as Markdown.HTMLBlock:
            return .html(.init(html: html.rawHTML))

        default:
            if markup.childCount > 0 {
                let nested = blocks(from: markup.children)
                return nested.isEmpty ? nil : .blockquote(nested)
            }
            return nil
        }
    }

    private static func tableBlock(from table: Markdown.Table) -> MarkdownBlock {
        let header = table.head.children.compactMap { child -> InlineContent? in
            guard let cell = child as? Markdown.Table.Cell else { return nil }
            return InlineContent(inlines(from: cell.children))
        }

        let rows = table.body.children.compactMap { child -> [InlineContent]? in
            guard let row = child as? Markdown.Table.Row else { return nil }
            return row.children.compactMap { cellMarkup in
                guard let cell = cellMarkup as? Markdown.Table.Cell else { return nil }
                return InlineContent(inlines(from: cell.children))
            }
        }

        return .table(.init(
            header: header,
            rows: rows,
            columnAlignments: table.columnAlignments.map(tableColumnAlignment(from:))
        ))
    }

    private static func tableColumnAlignment(from alignment: Markdown.Table.ColumnAlignment?) -> MarkdownTableColumnAlignment? {
        guard let alignment else { return nil }
        switch alignment {
        case .left:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        }
    }

    private static func listItems(from children: MarkupChildren) -> [MMMDCore.ListItem] {
        children.compactMap { child in
            guard let item = child as? Markdown.ListItem else { return nil }
            var converted = blocks(from: item.children)
            let taskState = extractTaskState(from: &converted)
            return MMMDCore.ListItem(blocks: converted, isChecked: taskState)
        }
    }

    private static func extractTaskState(from blocks: inout [MarkdownBlock]) -> Bool? {
        guard !blocks.isEmpty else { return nil }
        guard case .paragraph(let content) = blocks[0], let first = content.nodes.first else {
            return nil
        }

        let marker: String
        switch first {
        case .text(let text):
            marker = String(text.prefix(3)).lowercased()
        default:
            return nil
        }

        guard marker == "[ ]" || marker == "[x]" else { return nil }

        var nodes = content.nodes
        if case .text(let text) = nodes[0] {
            let stripped = text.dropFirst(3).trimmingCharacters(in: .whitespaces)
            if stripped.isEmpty {
                nodes.removeFirst()
            } else {
                nodes[0] = .text(stripped)
            }
        }
        blocks[0] = .paragraph(.init(nodes))
        return marker == "[x]"
    }

    private static func inlines(from children: MarkupChildren) -> [InlineNode] {
        children.flatMap { inline(from: $0) }
    }

    private static func inline(from markup: Markup) -> [InlineNode] {
        switch markup {
        case let text as Markdown.Text:
            return splitMathText(text.string)

        case let emphasis as Emphasis:
            return [.emphasis(inlines(from: emphasis.children))]

        case let strong as Strong:
            return [.strong(inlines(from: strong.children))]

        case let strike as Strikethrough:
            return inlines(from: strike.children)

        case let code as InlineCode:
            if code.code.hasPrefix("\\("), code.code.hasSuffix("\\)") {
                return [.math(String(code.code.dropFirst(2).dropLast(2)))]
            }
            return [.code(code.code)]

        case let link as Markdown.Link:
            return [.link(text: inlines(from: link.children), url: url(from: link.destination))]

        case let image as Markdown.Image:
            return [.image(alt: image.plainText, url: url(from: image.source))]

        case is SoftBreak:
            return [.softBreak]

        case is LineBreak:
            return [.lineBreak]

        case let html as InlineHTML:
            return [.html(html.rawHTML)]

        default:
            if markup.childCount > 0 {
                return inlines(from: markup.children)
            }
            return []
        }
    }

    private static func splitMathText(_ text: String) -> [InlineNode] {
        var nodes: [InlineNode] = []
        var buffer = ""
        var index = text.startIndex

        func flushBuffer() {
            guard !buffer.isEmpty else { return }
            nodes.append(.text(buffer))
            buffer.removeAll()
        }

        while index < text.endIndex {
            if text[index...].hasPrefix("\\("),
               let end = text[index...].range(of: "\\)")?.lowerBound {
                flushBuffer()
                let start = text.index(index, offsetBy: 2)
                nodes.append(.math(String(text[start..<end])))
                index = text.index(end, offsetBy: 2)
                continue
            }

            if text[index] == "$", text[text.index(after: index)...].firstIndex(of: "$") != nil {
                let next = text.index(after: index)
                if next < text.endIndex, text[next] == "$" {
                    buffer.append(text[index])
                    index = text.index(after: index)
                    continue
                }
                if let end = text[next...].firstIndex(of: "$") {
                    flushBuffer()
                    nodes.append(.math(String(text[next..<end])))
                    index = text.index(after: end)
                    continue
                }
            }

            buffer.append(text[index])
            index = text.index(after: index)
        }

        flushBuffer()
        return nodes
    }

    private static func url(from rawValue: String?) -> URL? {
        guard let rawValue, !rawValue.isEmpty else { return nil }
        if let url = URL(string: rawValue) {
            return url
        }
        return rawValue
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            .flatMap(URL.init(string:))
    }
}
