import Foundation

/// Lightweight LaTeX-to-text formatter used by the built-in fallback renderer.
///
/// This is intentionally conservative: it makes common formulas readable without
/// pretending to be a full TeX layout engine. Apps that need real math typesetting
/// can still provide a custom `MathRenderer`.
public enum LaTeXPlainTextFormatter {
    public static func fallbackText(for latex: String) -> String {
        var text = latex.trimmingCharacters(in: .whitespacesAndNewlines)
        text = replaceBinaryCommand("\\frac", in: text) { numerator, denominator in
            "(\(fallbackText(for: numerator))) / (\(fallbackText(for: denominator)))"
        }
        text = replaceBinaryCommand("\\binom", in: text) { top, bottom in
            "C(\(fallbackText(for: top)), \(fallbackText(for: bottom)))"
        }
        text = replaceUnaryCommand("\\sqrt", in: text) { value in
            "√(\(fallbackText(for: value)))"
        }
        text = replaceUnaryCommand("\\text", in: text) { value in
            value
        }
        text = replaceUnaryCommand("\\vec", in: text) { value in
            "vec(\(fallbackText(for: value)))"
        }
        text = replaceCommands(in: text)
        text = replaceScripts(in: text)
        text = text.replacingOccurrences(of: "{", with: "")
        text = text.replacingOccurrences(of: "}", with: "")
        text = text.replacingOccurrences(of: "\\", with: "")
        return collapseWhitespace(in: text)
    }

    private static func replaceCommands(in input: String) -> String {
        var text = input
        let replacements: [(String, String)] = [
            ("\\left", ""),
            ("\\right", ""),
            ("\\quad", " "),
            ("\\,", ""),
            ("\\pi", "π"),
            ("\\pm", "±"),
            ("\\sum", "∑"),
            ("\\int", "∫"),
            ("\\infty", "∞"),
            ("\\to", "→"),
            ("\\rightarrow", "→"),
            ("\\Rightarrow", "⇒"),
            ("\\Leftrightarrow", "⇔"),
            ("\\Delta", "Δ"),
            ("\\sigma", "σ"),
            ("\\times", "×"),
            ("\\cdot", "·"),
            ("\\leq", "≤"),
            ("\\le", "≤"),
            ("\\geq", "≥"),
            ("\\ge", "≥"),
            ("\\neq", "≠"),
            ("\\ne", "≠"),
            ("\\approx", "≈"),
            ("\\ln", "ln"),
            ("\\lim", "lim"),
            ("\\sin", "sin"),
            ("\\cos", "cos")
        ]

        for (source, replacement) in replacements {
            text = text.replacingOccurrences(of: source, with: replacement)
        }
        return text
    }

    private static func replaceUnaryCommand(
        _ command: String,
        in input: String,
        transform: (String) -> String
    ) -> String {
        var output = ""
        var index = input.startIndex

        while let range = input[index...].range(of: command) {
            output.append(contentsOf: input[index..<range.lowerBound])
            var cursor = range.upperBound
            skipSpaces(in: input, from: &cursor)

            guard cursor < input.endIndex,
                  input[cursor] == "{",
                  let group = parseBraceGroup(in: input, from: cursor)
            else {
                output.append(contentsOf: input[range])
                index = range.upperBound
                continue
            }

            output.append(transform(group.content))
            index = group.end
        }

        output.append(contentsOf: input[index...])
        return output
    }

    private static func replaceBinaryCommand(
        _ command: String,
        in input: String,
        transform: (String, String) -> String
    ) -> String {
        var output = ""
        var index = input.startIndex

        while let range = input[index...].range(of: command) {
            output.append(contentsOf: input[index..<range.lowerBound])
            var cursor = range.upperBound
            skipSpaces(in: input, from: &cursor)

            guard cursor < input.endIndex,
                  input[cursor] == "{",
                  let first = parseBraceGroup(in: input, from: cursor)
            else {
                output.append(contentsOf: input[range])
                index = range.upperBound
                continue
            }

            cursor = first.end
            skipSpaces(in: input, from: &cursor)

            guard cursor < input.endIndex,
                  input[cursor] == "{",
                  let second = parseBraceGroup(in: input, from: cursor)
            else {
                output.append(contentsOf: input[range])
                output.append("{\(first.content)}")
                index = first.end
                continue
            }

            output.append(transform(first.content, second.content))
            index = second.end
        }

        output.append(contentsOf: input[index...])
        return output
    }

    private static func parseBraceGroup(in input: String, from start: String.Index) -> (content: String, end: String.Index)? {
        guard start < input.endIndex, input[start] == "{" else { return nil }

        var depth = 0
        var cursor = start
        var contentStart: String.Index?

        while cursor < input.endIndex {
            let character = input[cursor]
            if character == "{" {
                depth += 1
                if depth == 1 {
                    contentStart = input.index(after: cursor)
                }
            } else if character == "}" {
                depth -= 1
                if depth == 0, let contentStart {
                    let end = input.index(after: cursor)
                    return (String(input[contentStart..<cursor]), end)
                }
            }
            cursor = input.index(after: cursor)
        }

        return nil
    }

    private static func replaceScripts(in input: String) -> String {
        var output = ""
        var index = input.startIndex

        while index < input.endIndex {
            let character = input[index]
            guard character == "^" || character == "_" else {
                output.append(character)
                index = input.index(after: index)
                continue
            }

            let marker = character
            var cursor = input.index(after: index)
            guard cursor < input.endIndex else {
                output.append(character)
                break
            }

            let value: String
            if input[cursor] == "{", let group = parseBraceGroup(in: input, from: cursor) {
                value = fallbackText(for: group.content)
                cursor = group.end
            } else {
                value = String(input[cursor])
                cursor = input.index(after: cursor)
            }

            if marker == "^" {
                output.append(superscript(value) ?? "^(\(value))")
            } else {
                output.append(subscriptText(value) ?? "_\(value)")
            }
            index = cursor
        }

        return output
    }

    private static func superscript(_ value: String) -> String? {
        let map: [Character: Character] = [
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
            "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
            "+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽", ")": "⁾",
            "n": "ⁿ", "i": "ⁱ"
        ]
        return mapped(value, using: map)
    }

    private static func subscriptText(_ value: String) -> String? {
        let map: [Character: Character] = [
            "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
            "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
            "+": "₊", "-": "₋", "=": "₌", "(": "₍", ")": "₎",
            "a": "ₐ", "e": "ₑ", "h": "ₕ", "i": "ᵢ", "j": "ⱼ",
            "k": "ₖ", "l": "ₗ", "m": "ₘ", "n": "ₙ", "o": "ₒ",
            "p": "ₚ", "r": "ᵣ", "s": "ₛ", "t": "ₜ", "u": "ᵤ",
            "v": "ᵥ", "x": "ₓ"
        ]
        return mapped(value, using: map)
    }

    private static func mapped(_ value: String, using map: [Character: Character]) -> String? {
        var output = ""
        for character in value {
            guard let replacement = map[character] else { return nil }
            output.append(replacement)
        }
        return output
    }

    private static func skipSpaces(in input: String, from index: inout String.Index) {
        while index < input.endIndex, input[index].isWhitespace {
            index = input.index(after: index)
        }
    }

    private static func collapseWhitespace(in input: String) -> String {
        input
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
