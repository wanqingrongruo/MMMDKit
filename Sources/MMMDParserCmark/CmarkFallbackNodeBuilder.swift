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
                    type: .table,
                    children: tableRows,
                    sourceRange: .init(startLine: startLine, startColumn: 1, endLine: endLine, endColumn: lines[endLine - 1].count + 1)
                ))
                continue
            }

            if let marker = ListMarker(line: line) {
                flushParagraph()
                let startLine = lineNumber
                var endLine = lineNumber
                var itemNodes: [CmarkNode] = []
                var currentLine = line

                while true {
                    guard let currentMarker = ListMarker(line: currentLine), currentMarker.style.matches(marker.style) else {
                        break
                    }

                    itemNodes.append(.init(
                        type: .listItem,
                        children: [
                            .init(
                                type: .paragraph,
                                children: CmarkInlineFallbackParser.parse(currentMarker.content),
                                sourceRange: .init(
                                    startLine: endLine,
                                    startColumn: currentMarker.contentStartColumn,
                                    endLine: endLine,
                                    endColumn: currentLine.count + 1
                                )
                            )
                        ],
                        sourceRange: .init(startLine: endLine, startColumn: 1, endLine: endLine, endColumn: currentLine.count + 1)
                    ))

                    guard index < lines.count else {
                        break
                    }
                    let nextLine = lines[index]
                    guard ListMarker(line: nextLine)?.style.matches(marker.style) == true else {
                        break
                    }
                    currentLine = nextLine
                    endLine = index + 1
                    index += 1
                }

                children.append(.init(
                    type: .list(style: marker.style),
                    children: itemNodes,
                    sourceRange: .init(startLine: startLine, startColumn: 1, endLine: endLine, endColumn: lines[endLine - 1].count + 1)
                ))
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

    init?(line: String) {
        if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
            style = .unordered
            content = String(line.dropFirst(2))
            contentStartColumn = 3
            return
        }

        let digits = line.prefix { $0.isNumber }
        guard !digits.isEmpty,
              let dotIndex = line.index(line.startIndex, offsetBy: digits.count, limitedBy: line.endIndex),
              dotIndex < line.endIndex,
              line[dotIndex] == ".",
              line.index(after: dotIndex) < line.endIndex,
              line[line.index(after: dotIndex)] == " ",
              let start = Int(digits) else {
            return nil
        }

        style = .ordered(start: start)
        content = String(line.dropFirst(digits.count + 2))
        contentStartColumn = digits.count + 3
    }
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
