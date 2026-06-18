import Foundation
import MMMDCore

enum CmarkFallbackNodeBuilder {
    static func buildDocument(from source: String) -> CmarkNode {
        var children: [CmarkNode] = []
        var paragraph: [String] = []
        var paragraphStartLine: Int?
        let lines = Array(source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))
        var index = 0

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            let startLine = paragraphStartLine ?? 1
            let endLine = startLine + paragraph.count - 1
            let endColumn = (paragraph.last?.count ?? 0) + 1
            children.append(.init(
                type: .paragraph,
                children: CmarkInlineFallbackParser.parse(paragraph.joined(separator: "\n")),
                sourceRange: .init(startLine: startLine, startColumn: 1, endLine: endLine, endColumn: endColumn)
            ))
            paragraph.removeAll()
            paragraphStartLine = nil
        }

        while index < lines.count {
            let line = lines[index]
            let lineNumber = index + 1
            index += 1

            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                flushParagraph()
                continue
            }

            if line.hasPrefix("```") {
                flushParagraph()
                let language = line.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
                var codeLines: [String] = []
                var endLine = lineNumber
                while index < lines.count {
                    let codeLine = lines[index]
                    endLine = index + 1
                    index += 1
                    if codeLine.hasPrefix("```") {
                        break
                    }
                    codeLines.append(codeLine)
                }
                children.append(.init(
                    type: .codeBlock(
                        language: language.isEmpty ? nil : language,
                        content: codeLines.joined(separator: "\n")
                    ),
                    sourceRange: .init(startLine: lineNumber, startColumn: 1, endLine: endLine, endColumn: (lines[endLine - 1].count) + 1)
                ))
                continue
            }

            if line.hasPrefix("$$") {
                flushParagraph()
                var mathLines: [String] = []
                var endLine = lineNumber
                let firstLine = String(line.dropFirst(2))
                if !firstLine.isEmpty {
                    mathLines.append(firstLine)
                }
                while index < lines.count {
                    let mathLine = lines[index]
                    endLine = index + 1
                    index += 1
                    if mathLine.hasPrefix("$$") {
                        break
                    }
                    mathLines.append(mathLine)
                }
                children.append(.init(
                    type: .mathBlock(latex: mathLines.joined(separator: "\n")),
                    sourceRange: .init(startLine: lineNumber, startColumn: 1, endLine: endLine, endColumn: lines[endLine - 1].count + 1)
                ))
                continue
            }

            if line.hasPrefix("#") {
                flushParagraph()
                let hashes = line.prefix { $0 == "#" }.count
                let text = line.dropFirst(hashes).trimmingCharacters(in: .whitespaces)
                children.append(.init(
                    type: .heading(level: min(hashes, 6)),
                    children: CmarkInlineFallbackParser.parse(text),
                    sourceRange: .init(startLine: lineNumber, startColumn: 1, endLine: lineNumber, endColumn: line.count + 1)
                ))
                continue
            }

            if line.hasPrefix(">") {
                flushParagraph()
                let startLine = lineNumber
                var quoteLines: [String] = [Self.unquoted(line)]
                var endLine = lineNumber
                while index < lines.count, lines[index].hasPrefix(">") {
                    quoteLines.append(Self.unquoted(lines[index]))
                    endLine = index + 1
                    index += 1
                }
                let nested = buildDocument(from: quoteLines.joined(separator: "\n")).children
                children.append(.init(
                    type: .blockquote,
                    children: nested,
                    sourceRange: .init(startLine: startLine, startColumn: 1, endLine: endLine, endColumn: lines[endLine - 1].count + 1)
                ))
                continue
            }

            if Self.isTableHeader(line: line, nextLine: index < lines.count ? lines[index] : nil) {
                flushParagraph()
                let startLine = lineNumber
                let headerLine = line
                let separatorLine = lines[index]
                let alignments = Self.tableAlignments(from: separatorLine)
                index += 1
                var rowLines: [String] = []
                var endLine = index
                while index < lines.count, Self.isTableRow(lines[index]) {
                    rowLines.append(lines[index])
                    endLine = index + 1
                    index += 1
                }

                var tableRows: [CmarkNode] = [
                    Self.tableRow(from: headerLine, isHeader: true, lineNumber: startLine)
                ]
                tableRows.append(contentsOf: rowLines.enumerated().map { offset, row in
                    Self.tableRow(from: row, isHeader: false, lineNumber: startLine + 2 + offset)
                })

                children.append(.init(
                    type: .table(alignments: alignments),
                    children: tableRows,
                    sourceRange: .init(startLine: startLine, startColumn: 1, endLine: endLine, endColumn: lines[endLine - 1].count + 1)
                ))
                continue
            }

            if let marker = ListMarker(line: line) {
                flushParagraph()
                if let parsed = Self.listNode(lines: lines, startIndex: lineNumber - 1, style: marker.style) {
                    children.append(parsed.node)
                    index = parsed.endIndex
                }
                continue
            }

            if line == "---" || line == "***" {
                flushParagraph()
                children.append(.init(
                    type: .thematicBreak,
                    sourceRange: .init(startLine: lineNumber, startColumn: 1, endLine: lineNumber, endColumn: line.count + 1)
                ))
                continue
            }

            if paragraph.isEmpty {
                paragraphStartLine = lineNumber
            }
            paragraph.append(line)
        }

        flushParagraph()
        return CmarkNode(type: .document, children: children)
    }

    private static func listNode(
        lines: [String],
        startIndex: Int,
        style: CmarkListStyle? = nil
    ) -> (node: CmarkNode, endIndex: Int)? {
        guard startIndex < lines.count,
              let firstMarker = ListMarker(line: lines[startIndex]) else {
            return nil
        }

        let listStyle = style ?? firstMarker.style
        let baseIndentation = firstMarker.indentation
        var index = startIndex
        var itemNodes: [CmarkNode] = []

        while index < lines.count {
            guard let marker = ListMarker(line: lines[index]),
                  marker.indentation == baseIndentation,
                  marker.style.matches(listStyle) else {
                break
            }

            let itemStartIndex = index
            let lineNumber = index + 1
            var itemChildren: [CmarkNode] = [
                paragraphNode(
                    text: marker.content,
                    startLine: lineNumber,
                    startColumn: marker.contentStartColumn,
                    endLine: lineNumber,
                    endColumn: lines[index].count + 1
                )
            ]
            var continuationLines: [(text: String, lineNumber: Int)] = []
            index += 1

            func flushContinuation() {
                let text = continuationLines
                    .map(\.text)
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty,
                      let first = continuationLines.first,
                      let last = continuationLines.last else {
                    continuationLines.removeAll()
                    return
                }

                itemChildren.append(paragraphNode(
                    text: text,
                    startLine: first.lineNumber,
                    startColumn: 1,
                    endLine: last.lineNumber,
                    endColumn: lines[last.lineNumber - 1].count + 1
                ))
                continuationLines.removeAll()
            }

            while index < lines.count {
                let nextLine = lines[index]
                let trimmed = nextLine.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    break
                }

                if let nextMarker = ListMarker(line: nextLine) {
                    if nextMarker.indentation == baseIndentation,
                       nextMarker.style.matches(listStyle) {
                        break
                    }

                    if nextMarker.indentation <= baseIndentation {
                        break
                    }

                    flushContinuation()
                    if let nested = listNode(lines: lines, startIndex: index, style: nextMarker.style) {
                        itemChildren.append(nested.node)
                        index = nested.endIndex
                        continue
                    }
                }

                let indentation = leadingIndentation(in: nextLine)
                guard indentation > baseIndentation else {
                    break
                }

                continuationLines.append((
                    text: removingIndentation(from: nextLine, count: min(indentation, baseIndentation + 2)),
                    lineNumber: index + 1
                ))
                index += 1
            }

            flushContinuation()
            let itemEndIndex = max(index - 1, itemStartIndex)
            itemNodes.append(.init(
                type: .listItem,
                children: itemChildren,
                sourceRange: .init(
                    startLine: itemStartIndex + 1,
                    startColumn: baseIndentation + 1,
                    endLine: itemEndIndex + 1,
                    endColumn: lines[itemEndIndex].count + 1
                )
            ))
        }

        guard !itemNodes.isEmpty else {
            return nil
        }

        let listEndIndex = max(index - 1, startIndex)
        return (
            .init(
                type: .list(style: listStyle),
                children: itemNodes,
                sourceRange: .init(
                    startLine: startIndex + 1,
                    startColumn: baseIndentation + 1,
                    endLine: listEndIndex + 1,
                    endColumn: lines[listEndIndex].count + 1
                )
            ),
            index
        )
    }

    private static func paragraphNode(
        text: String,
        startLine: Int,
        startColumn: Int,
        endLine: Int,
        endColumn: Int
    ) -> CmarkNode {
        .init(
            type: .paragraph,
            children: CmarkInlineFallbackParser.parse(text),
            sourceRange: .init(
                startLine: startLine,
                startColumn: startColumn,
                endLine: endLine,
                endColumn: endColumn
            )
        )
    }

    private static func unquoted(_ line: String) -> String {
        let withoutMarker = line.dropFirst()
        if withoutMarker.hasPrefix(" ") {
            return String(withoutMarker.dropFirst())
        }
        return String(withoutMarker)
    }

    private static func isTableHeader(line: String, nextLine: String?) -> Bool {
        guard isTableRow(line), let nextLine else {
            return false
        }
        let cells = splitTableRow(nextLine)
        return cells.count >= 2 && cells.allSatisfy { cell in
            let trimmed = cell.trimmingCharacters(in: .whitespaces)
            return trimmed.count >= 3 && trimmed.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }

    private static func isTableRow(_ line: String) -> Bool {
        splitTableRow(line).count >= 2
    }

    private static func tableRow(from line: String, isHeader: Bool, lineNumber: Int) -> CmarkNode {
        let cells = splitTableRow(line).map { cell in
            CmarkNode(
                type: .tableCell,
                children: CmarkInlineFallbackParser.parse(cell.trimmingCharacters(in: .whitespaces)),
                sourceRange: .init(startLine: lineNumber, startColumn: 1, endLine: lineNumber, endColumn: line.count + 1)
            )
        }
        return CmarkNode(
            type: .tableRow(isHeader: isHeader),
            children: cells,
            sourceRange: .init(startLine: lineNumber, startColumn: 1, endLine: lineNumber, endColumn: line.count + 1)
        )
    }

    private static func tableAlignments(from separatorLine: String) -> [MarkdownTableColumnAlignment?] {
        splitTableRow(separatorLine).map { cell in
            let trimmed = cell.trimmingCharacters(in: .whitespaces)
            let isLeading = trimmed.hasPrefix(":")
            let isTrailing = trimmed.hasSuffix(":")

            switch (isLeading, isTrailing) {
            case (true, true):
                return .center
            case (true, false):
                return .leading
            case (false, true):
                return .trailing
            case (false, false):
                return nil
            }
        }
    }

    private static func splitTableRow(_ line: String) -> [String] {
        var value = line.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("|") {
            value.removeFirst()
        }
        if value.hasSuffix("|") {
            value.removeLast()
        }
        return value.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
    }
}

private struct ListMarker {
    var style: CmarkListStyle
    var content: String
    var contentStartColumn: Int
    var indentation: Int

    init?(line: String) {
        let leadingCharacters = line.prefix { $0 == " " || $0 == "\t" }
        indentation = leadingIndentation(in: line)
        let markerText = line.dropFirst(leadingCharacters.count)

        if markerText.hasPrefix("- ") || markerText.hasPrefix("* ") || markerText.hasPrefix("+ ") {
            style = .unordered
            content = String(markerText.dropFirst(2))
            contentStartColumn = indentation + 3
            return
        }

        let digits = markerText.prefix { $0.isNumber }
        guard !digits.isEmpty,
              let dotIndex = markerText.index(markerText.startIndex, offsetBy: digits.count, limitedBy: markerText.endIndex),
              dotIndex < markerText.endIndex,
              markerText[dotIndex] == ".",
              markerText.index(after: dotIndex) < markerText.endIndex,
              markerText[markerText.index(after: dotIndex)] == " ",
              let start = Int(digits) else {
            return nil
        }

        style = .ordered(start: start)
        content = String(markerText.dropFirst(digits.count + 2))
        contentStartColumn = indentation + digits.count + 3
    }
}

private func leadingIndentation(in line: String) -> Int {
    line.reduce(into: (count: 0, isLeading: true)) { state, character in
        guard state.isLeading else { return }
        if character == " " {
            state.count += 1
        } else if character == "\t" {
            state.count += 4
        } else {
            state.isLeading = false
        }
    }.count
}

private func removingIndentation(from line: String, count: Int) -> String {
    var removed = 0
    var index = line.startIndex

    while index < line.endIndex, removed < count {
        let character = line[index]
        if character == " " {
            removed += 1
        } else if character == "\t" {
            removed += 4
        } else {
            break
        }
        index = line.index(after: index)
    }

    return String(line[index...])
}

private extension CmarkListStyle {
    func matches(_ other: CmarkListStyle) -> Bool {
        switch (self, other) {
        case (.unordered, .unordered), (.ordered, .ordered):
            return true
        default:
            return false
        }
    }
}
