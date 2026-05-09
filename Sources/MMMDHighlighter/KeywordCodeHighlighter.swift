import Foundation
import MMMDCore

public struct KeywordCodeHighlighter: CodeHighlighter {
    private let swiftKeywords: Set<String> = [
        "actor", "as", "associatedtype", "await", "break", "case", "catch", "class", "continue", "default",
        "defer", "do", "else", "enum", "extension", "fallthrough", "false", "fileprivate", "for", "func",
        "guard", "if", "import", "in", "init", "inout", "internal", "is", "let", "nil", "open", "operator",
        "private", "protocol", "public", "repeat", "rethrows", "return", "self", "static", "struct", "subscript",
        "super", "switch", "throw", "throws", "true", "try", "typealias", "var", "where", "while"
    ]

    public init() {}

    public func highlight(code: String, language: String?, theme: CodeTheme) async throws -> HighlightResult {
        let normalizedLanguage = language?.lowercased()
        guard normalizedLanguage == nil || normalizedLanguage == "swift" else {
            return HighlightResult(language: language, tokens: [.init(text: code)])
        }

        return HighlightResult(language: language, tokens: tokenizeSwift(code))
    }

    private func tokenizeSwift(_ code: String) -> [HighlightToken] {
        var tokens: [HighlightToken] = []
        var index = code.startIndex

        while index < code.endIndex {
            if code[index...].hasPrefix("//") {
                let lineEnd = code[index...].firstIndex(of: "\n") ?? code.endIndex
                tokens.append(.init(text: String(code[index..<lineEnd]), scope: "comment"))
                index = lineEnd
                continue
            }

            if code[index] == "\"" {
                let start = index
                index = code.index(after: index)
                while index < code.endIndex {
                    if code[index] == "\"" {
                        index = code.index(after: index)
                        break
                    }
                    index = code.index(after: index)
                }
                tokens.append(.init(text: String(code[start..<index]), scope: "string"))
                continue
            }

            if code[index].isNumber {
                let start = index
                while index < code.endIndex, code[index].isNumber {
                    index = code.index(after: index)
                }
                tokens.append(.init(text: String(code[start..<index]), scope: "number"))
                continue
            }

            if code[index].isLetter || code[index] == "_" {
                let start = index
                while index < code.endIndex, code[index].isLetter || code[index].isNumber || code[index] == "_" {
                    index = code.index(after: index)
                }
                let word = String(code[start..<index])
                tokens.append(.init(text: word, scope: swiftKeywords.contains(word) ? "keyword" : nil))
                continue
            }

            tokens.append(.init(text: String(code[index])))
            index = code.index(after: index)
        }

        return tokens
    }
}
