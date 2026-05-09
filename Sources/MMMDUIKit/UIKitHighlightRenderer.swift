import MMMDCore

#if canImport(UIKit)
import UIKit

enum UIKitHighlightRenderer {
    static func attributedString(from result: HighlightResult, theme: CodeTheme, baseFont: UIFont) -> NSAttributedString {
        let output = NSMutableAttributedString()
        for token in result.tokens {
            output.append(NSAttributedString(string: token.text, attributes: attributes(for: token, theme: theme, baseFont: baseFont)))
        }
        return output
    }

    private static func attributes(for token: HighlightToken, theme: CodeTheme, baseFont: UIFont) -> [NSAttributedString.Key: Any] {
        guard let scope = token.scope, let style = theme.tokenStyles[scope] else {
            return [.font: baseFont, .foregroundColor: UIColor.label]
        }

        var font = baseFont
        if style.fontTraits.contains("bold") {
            font = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor, size: font.pointSize)
        } else if style.fontTraits.contains("italic") {
            font = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic) ?? font.fontDescriptor, size: font.pointSize)
        }

        return [.font: font, .foregroundColor: color(named: style.foregroundColor)]
    }

    private static func color(named name: String) -> UIColor {
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
            return .secondaryLabel
        default:
            return .label
        }
    }
}
#endif
