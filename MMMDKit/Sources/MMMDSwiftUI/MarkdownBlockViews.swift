import Foundation
import MMMDCore
import SwiftUI

struct MarkdownBlockView: View {
    let block: MarkdownBlock
    let context: SwiftUIMarkdownContext
    let nestingLevel: Int

    init(block: MarkdownBlock, context: SwiftUIMarkdownContext, nestingLevel: Int = 0) {
        self.block = block
        self.context = context
        self.nestingLevel = nestingLevel
    }

    var body: some View {
        switch block {
        case .paragraph(let content):
            MarkdownInlineTextView(content: content, context: context)
        case .heading(let level, let content):
            MarkdownHeadingView(level: level, content: content, context: context)
        case .blockquote(let blocks):
            MarkdownBlockquoteView(blocks: blocks, context: context, nestingLevel: nestingLevel)
        case .list(let list):
            MarkdownListView(list: list, context: context, nestingLevel: nestingLevel)
        case .code(let code):
            MarkdownCodeBlockView(code: code, context: context)
        case .table(let table):
            MarkdownTableView(table: table, context: context)
        case .math(let math):
            MarkdownMathBlockView(math: math, context: context)
        case .html(let html):
            MarkdownHTMLFallbackView(html: html, context: context)
        case .image(let image):
            MarkdownImageBlockView(image: image, context: context)
        case .thematicBreak:
            Divider()
                .background(MMMDStyleResolver.color(context.configuration.theme.colors.tableBorder))
                .frame(height: 4)
                .padding(.vertical, 8)
        case .custom(let custom):
            Text(custom.payload)
                .font(MMMDStyleResolver.font(context.configuration.theme.typography.body))
                .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.text))
        }
    }
}

struct MarkdownInlineTextView: View {
    let content: InlineContent
    let context: SwiftUIMarkdownContext

    var body: some View {
        Text(InlineAttributedStringBuilder.attributedString(from: content, context: context))
            .lineSpacing(context.configuration.theme.spacing.lineSpacing)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct MarkdownHeadingView: View {
    let level: Int
    let content: InlineContent
    let context: SwiftUIMarkdownContext

    var body: some View {
        Text(InlineAttributedStringBuilder.attributedString(
            from: content,
            context: context,
            baseFont: font,
            baseColor: MMMDStyleResolver.color(context.configuration.theme.colors.text)
        ))
        .textSelection(.enabled)
        .accessibilityAddTraits(.isHeader)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var font: Font {
        switch level {
        case 1:
            return MMMDStyleResolver.font(context.configuration.theme.typography.heading1)
        case 2:
            return MMMDStyleResolver.font(context.configuration.theme.typography.heading2)
        default:
            return .system(size: max(16, context.configuration.theme.typography.heading2.pointSize - Double(level - 2) * 1.5), weight: .semibold)
        }
    }
}

struct MarkdownBlockquoteView: View {
    let blocks: [MarkdownBlock]
    let context: SwiftUIMarkdownContext
    let nestingLevel: Int

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(MMMDStyleResolver.color(context.configuration.theme.colors.quoteBorder))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    MarkdownBlockView(block: block, context: context, nestingLevel: nestingLevel)
                        .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.secondaryText))
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct MarkdownListView: View {
    let list: ListBlock
    let context: SwiftUIMarkdownContext
    let nestingLevel: Int

    var body: some View {
        VStack(alignment: .leading, spacing: itemSpacing) {
            ForEach(Array(list.items.enumerated()), id: \.offset) { offset, item in
                listItemView(item: item, offset: offset)
            }
        }
        .padding(.leading, nestedLeadingPadding)
    }

    private func listItemView(item: ListItem, offset: Int) -> some View {
        VStack(alignment: .leading, spacing: itemSpacing) {
            HStack(alignment: .mmmdListFirstLineCenter, spacing: markerSpacing) {
                markerView(for: item, offset: offset)

                if let firstBlock = item.blocks.first {
                    MarkdownBlockView(block: firstBlock, context: context, nestingLevel: nestingLevel)
                        .alignmentGuide(.mmmdListFirstLineCenter) { dimensions in
                            let heightAfterFirstLine = dimensions[.lastTextBaseline] - dimensions[.firstTextBaseline]
                            let heightOfFirstLine = dimensions.height - heightAfterFirstLine
                            return heightOfFirstLine / 2
                        }
                }

                Spacer(minLength: 0)
            }

            if item.blocks.count > 1 {
                VStack(alignment: .leading, spacing: itemSpacing) {
                    ForEach(Array(item.blocks.dropFirst().enumerated()), id: \.offset) { _, block in
                        MarkdownBlockView(
                            block: block,
                            context: context,
                            nestingLevel: block.isList ? nestingLevel + 1 : nestingLevel
                        )
                        .padding(.leading, block.isList ? 0 : continuationLeadingPadding)
                    }
                }
            }
        }
        .accessibilityLabel("\(context.configuration.localization.listItem) \(offset + 1)")
    }

    @ViewBuilder
    private func markerView(for item: ListItem, offset: Int) -> some View {
        switch list.style {
        case .ordered(let start):
            Text("\(start + offset).")
                .font(MMMDStyleResolver.font(context.configuration.theme.typography.body))
                .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.secondaryText))
                .frame(width: markerWidth, alignment: .trailing)
                .alignmentGuide(.mmmdListFirstLineCenter) { dimensions in
                    dimensions.height / 2
                }
        case .unordered:
            Image(systemName: nestingLevel.isMultiple(of: 2) ? "circle.fill" : "circle")
                .resizable()
                .frame(width: 4, height: 4)
                .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.secondaryText))
                .frame(width: markerWidth, alignment: .trailing)
                .alignmentGuide(.mmmdListFirstLineCenter) { dimensions in
                    dimensions.height / 2
                }
        case .task:
            Image(systemName: item.isChecked == true ? "checkmark.square" : "square")
                .font(MMMDStyleResolver.font(context.configuration.theme.typography.body))
                .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.secondaryText))
                .frame(width: markerWidth, alignment: .trailing)
                .alignmentGuide(.mmmdListFirstLineCenter) { dimensions in
                    dimensions.height / 2
                }
        }
    }

    private var itemSpacing: CGFloat {
        CGFloat(context.configuration.theme.spacing.paragraphSpacing)
    }

    private var markerWidth: CGFloat {
        CGFloat(context.configuration.theme.spacing.listIndent)
    }

    private var markerSpacing: CGFloat {
        switch list.style {
        case .ordered:
            return 11
        case .unordered, .task:
            return 1
        }
    }

    private var nestedLeadingPadding: CGFloat {
        CGFloat(nestingLevel) * 8
    }

    private var continuationLeadingPadding: CGFloat {
        markerWidth + markerSpacing
    }
}

private extension MarkdownBlock {
    var isList: Bool {
        if case .list = self {
            return true
        }
        return false
    }
}

extension VerticalAlignment {
    private enum MMMDListFirstLineCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            let heightAfterFirstLine = context[.lastTextBaseline] - context[.firstTextBaseline]
            let heightOfFirstLine = context.height - heightAfterFirstLine
            return heightOfFirstLine / 2
        }
    }

    static let mmmdListFirstLineCenter = Self(MMMDListFirstLineCenter.self)
}

struct MarkdownHTMLFallbackView: View {
    let html: HTMLBlock
    let context: SwiftUIMarkdownContext

    var body: some View {
        Text(html.html)
            .font(MMMDStyleResolver.font(context.configuration.theme.typography.code))
            .foregroundStyle(MMMDStyleResolver.color(context.configuration.theme.colors.secondaryText))
            .textSelection(.enabled)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MMMDStyleResolver.color(context.configuration.theme.colors.codeBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
