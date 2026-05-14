import MMMDCore

#if canImport(UIKit)
import UIKit

enum UIKitInlineRenderer {
    static func attributedString(from content: InlineContent, baseFont: UIFont, textColor: UIColor = .label, linkColor: UIColor = .systemBlue) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for node in content.nodes {
            result.append(attributedString(from: node, baseFont: baseFont, textColor: textColor, linkColor: linkColor))
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = baseFont.pointSize * 1.5
        paragraphStyle.maximumLineHeight = baseFont.pointSize * 1.5
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: result.length))
        return result
    }

    private static func attributedString(from node: InlineNode, baseFont: UIFont, textColor: UIColor, linkColor: UIColor) -> NSAttributedString {
        switch node {
        case .text(let value):
            return NSAttributedString(string: value, attributes: [.font: baseFont, .foregroundColor: textColor])
        case .emphasis(let nodes):
            return composed(nodes, font: italicFont(from: baseFont), textColor: textColor, linkColor: linkColor)
        case .strong(let nodes):
            return composed(nodes, font: boldFont(from: baseFont), textColor: textColor, linkColor: linkColor)
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

    private static func composed(_ nodes: [InlineNode], font: UIFont, textColor: UIColor, linkColor: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for node in nodes {
            result.append(attributedString(from: node, baseFont: font, textColor: textColor, linkColor: linkColor))
        }
        return result
    }

    private static func boldFont(from font: UIFont) -> UIFont {
        UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor, size: font.pointSize)
    }

    private static func italicFont(from font: UIFont) -> UIFont {
        UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic) ?? font.fontDescriptor, size: font.pointSize)
    }
}
#endif
