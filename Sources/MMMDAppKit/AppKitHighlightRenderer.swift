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
            return NSColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
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
            return .secondaryLabelColor
        default:
            return .labelColor
        }
    }
}
#endif
