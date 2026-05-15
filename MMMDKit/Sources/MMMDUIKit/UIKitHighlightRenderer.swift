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
        if name.hasPrefix("#") {
            let hex = name.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)
            let a, r, g, b: UInt64
            switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (a, r, g, b) = (255, 0, 0, 0)
            }
            return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
        }
        
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
