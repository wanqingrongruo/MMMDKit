import Foundation
import Markdown
import MMMDCore

/// 基于 `swift-markdown` 的默认 SPM 解析器。
///
/// CocoaPods 仍使用 `MMMDParserCmark` 的 fallback parser，以避免 vendoring swift-markdown/swift-cmark。
public final class SwiftMarkdownParser: MarkdownParser {
    public init() {}

    public func parse(_ source: String, options: MMMDCore.ParseOptions = .init()) throws -> MarkdownDocument {
        let preparedSource = SwiftMarkdownPreprocessor.prepare(source, options: options)
        let document = Document(parsing: preparedSource)
        let blocks = SwiftMarkdownNodeConverter.blocks(from: document.children)
        return MarkdownDocument(blocks: blocks, source: source)
    }
}

enum SwiftMarkdownPreprocessor {
    static func prepare(_ source: String, options: MMMDCore.ParseOptions) -> String {
        var result = source
        if options.speculativeRewrite, options.incompleteMarkdownPolicy == .streamingFriendly {
            result = IncompleteMarkdownRewriter.rewrite(result)
        }
        return MathPreprocessor.rewriteInlineMath(in: MathPreprocessor.rewriteBlockMath(in: result))
    }
}

enum MathPreprocessor {
    private static let fenceLanguage = "blockmath"

    static func rewriteBlockMath(in source: String) -> String {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var output: [String] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "$$" || trimmed == "\\[" {
                let close = trimmed == "$$" ? "$$" : "\\]"
                var mathLines: [String] = []
                index += 1
                while index < lines.count {
                    let candidate = lines[index]
                    if candidate.trimmingCharacters(in: .whitespaces) == close {
                        break
                    }
                    mathLines.append(candidate)
                    index += 1
                }
                output.append("```\(fenceLanguage)")
                output.append(contentsOf: mathLines)
                output.append("```")
                if index < lines.count {
                    index += 1
                }
                continue
            }

            if trimmed.hasPrefix("$$"), trimmed.hasSuffix("$$"), trimmed.count > 4 {
                let latex = trimmed.dropFirst(2).dropLast(2).trimmingCharacters(in: .whitespaces)
                output.append("```\(fenceLanguage)")
                output.append(latex)
                output.append("```")
                index += 1
                continue
            }

            output.append(line)
            index += 1
        }

        return output.joined(separator: "\n")
    }

    static func rewriteInlineMath(in source: String) -> String {
        var output = ""
        var index = source.startIndex

        while index < source.endIndex {
            if source[index...].hasPrefix("\\("),
               let close = source[index...].range(of: "\\)")?.lowerBound {
                let start = source.index(index, offsetBy: 2)
                let latex = source[start..<close]
                output += "`\\(\(latex)\\)`"
                index = source.index(close, offsetBy: 2)
                continue
            }

            if source[index] == "$" {
                let next = source.index(after: index)
                if next < source.endIndex, source[next] == "$" {
                    output.append(source[index])
                    index = next
                    continue
                }
                if let close = source[next...].firstIndex(of: "$") {
                    let latex = source[next..<close]
                    output += "`\\(\(latex)\\)`"
                    index = source.index(after: close)
                    continue
                }
            }

            output.append(source[index])
            index = source.index(after: index)
        }

        return output
    }
}

enum IncompleteMarkdownRewriter {
    static func rewrite(_ source: String) -> String {
        var result = source
        result = closeUnfinishedFence(in: result)
        result = closeUnfinishedDisplayMath(in: result)
        result = completePartialTable(in: result)
        result = closeTrailingEmphasis(in: result)
        return result
    }

    private static func closeUnfinishedFence(in source: String) -> String {
        let fenceCount = source.components(separatedBy: "```").count - 1
        guard fenceCount % 2 == 1 else { return source }
        return source + "\n```"
    }

    private static func closeUnfinishedDisplayMath(in source: String) -> String {
        let markerCount = source.components(separatedBy: "$$").count - 1
        guard markerCount % 2 == 1 else { return source }
        return source + "\n$$"
    }

    private static func completePartialTable(in source: String) -> String {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let last = lines.last?.trimmingCharacters(in: .whitespaces), last.hasPrefix("|") else {
            return source
        }

        if lines.count >= 2 {
            let previous = lines[lines.count - 2].trimmingCharacters(in: .whitespaces)
            if previous.hasPrefix("|"), !isTableDelimiter(last) {
                let cells = max(2, previous.split(separator: "|", omittingEmptySubsequences: false).count - 1)
                let delimiter = Array(repeating: "---", count: cells).joined(separator: " | ")
                return lines.dropLast().joined(separator: "\n") + "\n| \(delimiter) |"
            }
        }

        if !source.contains("\n| ---") {
            let cells = max(2, last.split(separator: "|", omittingEmptySubsequences: false).count - 1)
            let delimiter = Array(repeating: "---", count: cells).joined(separator: " | ")
            return source + "\n| \(delimiter) |"
        }

        return source
    }

    private static func isTableDelimiter(_ line: String) -> Bool {
        line
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .allSatisfy { cell in
                cell.count >= 3 && cell.allSatisfy { $0 == "-" || $0 == ":" }
            }
    }

    private static func closeTrailingEmphasis(in source: String) -> String {
        guard let lastLine = source.split(separator: "\n", omittingEmptySubsequences: false).last else {
            return source
        }
        let line = String(lastLine)
        if hasUnmatchedTrailingMarker("**", in: line) {
            return source + "**"
        }
        if hasUnmatchedTrailingMarker("*", in: line), !line.hasSuffix("**") {
            return source + "*"
        }
        return source
    }

    private static func hasUnmatchedTrailingMarker(_ marker: String, in line: String) -> Bool {
        guard line.range(of: marker, options: .backwards) != nil else { return false }
        let count = line.components(separatedBy: marker).count - 1
        return count % 2 == 1
    }
}
