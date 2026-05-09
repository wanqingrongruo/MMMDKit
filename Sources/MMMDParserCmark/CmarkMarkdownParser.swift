import Foundation
import MMMDCore

public final class CmarkMarkdownParser: MarkdownParser {
    public init() {}

    public func parse(_ source: String, options: ParseOptions = .init()) throws -> MarkdownDocument {
        // 这里先保留占位解析器，后续接入 cmark-gfm 时保持公开适配层形状稳定。
        let blocks = SimpleMarkdownParser.parseBlocks(source)
        return MarkdownDocument(blocks: blocks, source: source)
    }
}

enum SimpleMarkdownParser {
    static func parseBlocks(_ source: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var lines = Array(source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            blocks.append(.paragraph(.init(text: paragraph.joined(separator: "\n"))))
            paragraph.removeAll()
        }

        while !lines.isEmpty {
            let line = lines.removeFirst()

            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                flushParagraph()
                continue
            }

            if line.hasPrefix("```") {
                flushParagraph()
                let language = line.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
                var codeLines: [String] = []
                while !lines.isEmpty {
                    let codeLine = lines.removeFirst()
                    if codeLine.hasPrefix("```") {
                        break
                    }
                    codeLines.append(codeLine)
                }
                blocks.append(.code(.init(
                    language: language.isEmpty ? nil : language,
                    content: codeLines.joined(separator: "\n")
                )))
                continue
            }

            if line.hasPrefix("#") {
                flushParagraph()
                let hashes = line.prefix { $0 == "#" }.count
                let text = line.dropFirst(hashes).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: min(hashes, 6), content: .init(text: text)))
                continue
            }

            if line == "---" || line == "***" {
                flushParagraph()
                blocks.append(.thematicBreak)
                continue
            }

            paragraph.append(line)
        }

        flushParagraph()
        return blocks
    }
}
