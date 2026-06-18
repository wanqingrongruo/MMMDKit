import Foundation
import MMMDCore
import MMMDMath
import SwiftUI

enum InlineAttributedStringBuilder {
    static func attributedString(
        from content: InlineContent,
        context: SwiftUIMarkdownContext,
        baseFont: Font? = nil,
        baseColor: Color? = nil
    ) -> AttributedString {
        content.nodes.reduce(into: AttributedString()) { result, node in
            result.append(attributedString(
                from: node,
                context: context,
                font: baseFont ?? MMMDStyleResolver.font(context.configuration.theme.typography.body),
                color: baseColor ?? MMMDStyleResolver.color(context.configuration.theme.colors.text)
            ))
        }
    }

    private static func attributedString(
        from node: InlineNode,
        context: SwiftUIMarkdownContext,
        font: Font,
        color: Color
    ) -> AttributedString {
        switch node {
        case .text(let text):
            return styled(text, font: font, color: color)
        case .code(let code):
            var inlineCode = styled(
                code,
                font: MMMDStyleResolver.font(context.configuration.theme.typography.code),
                color: MMMDStyleResolver.color(context.configuration.theme.colors.text)
            )
            inlineCode.backgroundColor = MMMDStyleResolver.color(context.configuration.theme.colors.codeBackground)
            return inlineCode
        case .math(let latex):
            let mathFont = MMMDStyleResolver.font(.init(
                textStyle: context.configuration.theme.typography.body.textStyle,
                pointSize: context.configuration.theme.typography.body.pointSize,
                weight: context.configuration.theme.typography.body.weight,
                design: "serif"
            ))
            return styled(LaTeXPlainTextFormatter.fallbackText(for: latex), font: mathFont, color: color)
        case .html(let html):
            return styled(html, font: font, color: color)
        case .softBreak:
            return styled(" ", font: font, color: color)
        case .lineBreak:
            return styled("\n", font: font, color: color)
        case .emphasis(let nodes):
            return nodes.reduce(into: AttributedString()) { partial, child in
                partial.append(attributedString(from: child, context: context, font: font, color: color))
            }
        case .strong(let nodes):
            let strongFont = MMMDStyleResolver.font(.init(
                textStyle: context.configuration.theme.typography.body.textStyle,
                pointSize: context.configuration.theme.typography.body.pointSize,
                weight: "semibold",
                design: context.configuration.theme.typography.body.design
            ))
            return nodes.reduce(into: AttributedString()) { partial, child in
                partial.append(attributedString(from: child, context: context, font: strongFont, color: color))
            }
        case .link(let nodes, let url):
            var string = nodes.reduce(into: AttributedString()) { partial, child in
                partial.append(attributedString(from: child, context: context, font: font, color: MMMDStyleResolver.color(context.configuration.theme.colors.link)))
            }
            if let url {
                string.link = url
            }
            return string
        case .image(let alt, _):
            return styled(alt, font: font, color: color)
        case .custom(_, let payload):
            return styled(payload, font: font, color: color)
        }
    }

    private static func styled(_ text: String, font: Font, color: Color) -> AttributedString {
        var result = AttributedString(text)
        result.font = font
        result.foregroundColor = color
        return result
    }
}
