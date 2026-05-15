import MMMDCore

#if canImport(AppKit)
import AppKit

enum AppKitInlineRenderer {
    static func attributedString(from content: InlineContent, baseFont: NSFont, textColor: NSColor = .labelColor, linkColor: NSColor = .linkColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for node in content.nodes {
            result.append(attributedString(from: node, baseFont: baseFont, textColor: textColor, linkColor: linkColor))
        }
        return result
    }

    private static func attributedString(from node: InlineNode, baseFont: NSFont, textColor: NSColor, linkColor: NSColor) -> NSAttributedString {
        switch node {
        case .text(let value):
            return NSAttributedString(string: value, attributes: [.font: baseFont, .foregroundColor: textColor])
        case .emphasis(let nodes):
            return composed(nodes, font: convertedFont(from: baseFont, traits: .italicFontMask), textColor: textColor, linkColor: linkColor)
        case .strong(let nodes):
            return composed(nodes, font: convertedFont(from: baseFont, traits: .boldFontMask), textColor: textColor, linkColor: linkColor)
        case .link(let nodes, let url):
            let value = NSMutableAttributedString(attributedString: composed(nodes, font: baseFont, textColor: textColor, linkColor: linkColor))
            let range = NSRange(location: 0, length: value.length)
            if let url {
                value.addAttributes([.link: url, .foregroundColor: linkColor], range: range)
            }
            return value
        case .code(let value), .math(let value), .html(let value), .custom(_, let value):
            return NSAttributedString(string: value, attributes: [.font: baseFont, .foregroundColor: textColor])
        case .image(let alt, _):
            return NSAttributedString(string: alt, attributes: [.font: baseFont, .foregroundColor: textColor])
        case .softBreak, .lineBreak:
            return NSAttributedString(string: "\n", attributes: [.font: baseFont])
        }
    }

    private static func composed(_ nodes: [InlineNode], font: NSFont, textColor: NSColor, linkColor: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for node in nodes {
            result.append(attributedString(from: node, baseFont: font, textColor: textColor, linkColor: linkColor))
        }
        return result
    }

    private static func convertedFont(from font: NSFont, traits: NSFontTraitMask) -> NSFont {
        NSFontManager.shared.convert(font, toHaveTrait: traits)
    }
}
#endif
