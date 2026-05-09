import MMMDCore

#if canImport(AppKit)
import AppKit

enum AppKitHighlightRenderer {
    static func attributedString(from result: HighlightResult, theme: CodeTheme, baseFont: NSFont) -> NSAttributedString {
        let output = NSMutableAttributedString()
        for token in result.tokens {
            output.append(NSAttributedString(string: token.text, attributes: attributes(for: token, theme: theme, baseFont: baseFont)))
        }
        return output
    }

    private static func attributes(for token: HighlightToken, theme: CodeTheme, baseFont: NSFont) -> [NSAttributedString.Key: Any] {
        guard let scope = token.scope, let style = theme.tokenStyles[scope] else {
            return [.font: baseFont, .foregroundColor: NSColor.labelColor]
        }

        var font = baseFont
        if style.fontTraits.contains("bold") {
            font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        } else if style.fontTraits.contains("italic") {
            font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }

        return [.font: font, .foregroundColor: color(named: style.foregroundColor)]
    }

    private static func color(named name: String) -> NSColor {
        switch name {
        case "systemPurple":
            return .systemPurple
        case "systemRed":
            return .systemRed
        case "systemOrange":
            return .systemOrange
        case "systemGreen":
            return .systemGreen
        case "secondaryLabel":
            return .secondaryLabelColor
        default:
            return .labelColor
        }
    }
}
#endif
