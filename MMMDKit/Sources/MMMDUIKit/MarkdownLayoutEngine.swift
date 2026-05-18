import Foundation
import MMMDCore

#if canImport(UIKit)
import UIKit

/// UIKit 渲染层的 Markdown 尺寸测量结果。
///
/// 该结构只描述 Markdown 内容本身的排版尺寸，不包含业务容器的标题、头像、气泡内边距等额外 UI。
public struct MarkdownLayoutResult {
    /// 本次测量结果的唯一标识，便于列表或 cell 判断布局是否发生变化。
    public let id: UUID
    /// Markdown 内容在给定宽度约束下需要的尺寸。
    public let size: CGSize

    public init(id: UUID = UUID(), size: CGSize) {
        self.id = id
        self.size = size
    }
}

/// Markdown 文档的轻量级离屏测量引擎。
///
/// `MarkdownLayoutEngine` 用于在列表场景中提前计算 `MarkdownDocument` 的显示尺寸。
/// 它不创建完整的 `MarkdownView`，而是复用文本排版和块级元素高度计算逻辑，适合聊天列表、
/// collection view 预排版等需要提前知道高度的场景。
public enum MarkdownLayoutEngine {
    /// 测量一份 Markdown 文档在指定宽度下的内容尺寸。
    /// - Parameters:
    ///   - document: 要测量的 Markdown 文档。
    ///   - width: Markdown 内容区域的最大可用宽度，不包含业务容器外部 padding。
    ///   - configuration: 渲染配置，测量会使用其中的主题、插件、代码高亮和图片/公式策略。
    /// - Returns: Markdown 内容尺寸。
    public static func measure(
        document: MarkdownDocument,
        fittingWidth width: CGFloat,
        configuration: MarkdownConfiguration
    ) -> MarkdownLayoutResult {
        let transformedDocument = (try? configuration.transformedDocument(document)) ?? document
        let context = RenderContext(
            theme: configuration.theme,
            actions: configuration.actions,
            toolbarOptions: configuration.toolbarOptions,
            blockRendererRegistry: configuration.blockRendererRegistry,
            inlineRendererRegistry: configuration.inlineRendererRegistry,
            codeHighlighter: configuration.codeHighlighter,
            mathRenderer: configuration.mathRenderer,
            imageLoader: configuration.imageLoader,
            codeBlockMaximumWidth: configuration.codeBlockMaximumWidth
        )
        return measure(document: transformedDocument, fittingWidth: width, context: context)
    }

    static func measure(
        document: MarkdownDocument,
        fittingWidth width: CGFloat,
        context: RenderContext
    ) -> MarkdownLayoutResult {
        let contentWidth = max(1, width)
        let resultString = NSMutableAttributedString()
        var currentTextBlocks: [MarkdownBlock] = []

        func flushTextBlocks() {
            guard !currentTextBlocks.isEmpty else { return }
            let attr = TextBlockView.attributedString(
                for: currentTextBlocks,
                context: context,
                cacheKey: nil,
                textColor: .label,
                listLevel: 0,
                blockquoteLevel: 0
            )
            resultString.append(attr)
            currentTextBlocks.removeAll()
        }

        for (blockIndex, block) in document.blocks.enumerated() {
            switch block {
            case .heading, .paragraph, .list:
                currentTextBlocks.append(block)
                continue
            default:
                flushTextBlocks()
            }

            let hasPreviousContent = resultString.length > 0
            if hasPreviousContent && resultString.string.last != "\n" {
                resultString.append(NSAttributedString(string: "\n"))
            }

            let blockSize = measuredSize(for: block, fittingWidth: contentWidth, context: context)
            let attachment = NSTextAttachment()
            attachment.bounds = CGRect(origin: .zero, size: blockSize)
            attachment.image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }

            let hasFollowingContent = blockIndex + 1 < document.blocks.count
            let attachString = NSMutableAttributedString(string: hasFollowingContent ? "\u{FFFC}\n" : "\u{FFFC}")
            attachString.addAttribute(.attachment, value: attachment, range: NSRange(location: 0, length: 1))

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacingBefore = hasPreviousContent ? context.theme.spacing.blockSpacing : 0
            paragraphStyle.paragraphSpacing = needsTrailingSpacing(after: blockIndex, in: document.blocks) ? context.theme.spacing.blockSpacing : 0
            attachString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attachString.length))

            resultString.append(attachString)
        }
        flushTextBlocks()

        let textStorage = NSTextStorage(attributedString: resultString)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: contentWidth, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)

        let usedRect = layoutManager.usedRect(for: textContainer)
        return MarkdownLayoutResult(
            size: CGSize(
                width: min(ceil(usedRect.width), contentWidth),
                height: ceil(usedRect.height)
            )
        )
    }

    private static func measuredSize(
        for block: MarkdownBlock,
        fittingWidth width: CGFloat,
        context: RenderContext
    ) -> CGSize {
        var blockWidth = max(1, width)
        let blockHeight: CGFloat

        switch block {
        case .code(let codeBlock):
            blockHeight = CodeBlockView.exactHeight(for: codeBlock, width: blockWidth, context: context)
        case .table(let table):
            let minCellWidth: CGFloat = 132
            let columnCount = max((table.rows.map(\.count).max() ?? 0), table.header.count, 1)
            let contentWidth = CGFloat(columnCount) * minCellWidth
            blockWidth = min(contentWidth, blockWidth)
            blockHeight = TableBlockView.exactHeight(for: table, width: blockWidth, context: context)
        case .math(let mathBlock):
            blockHeight = MathBlockView.exactHeight(for: mathBlock, width: blockWidth, context: context)
        case .html(let htmlBlock):
            blockHeight = HTMLBlockView.exactHeight(for: htmlBlock, width: blockWidth, context: context)
        case .image(let imageBlock):
            blockHeight = ImageBlockView.exactHeight(for: imageBlock, width: blockWidth, context: context)
        case .blockquote(let blocks):
            blockHeight = BlockquoteBlockView.exactHeight(for: blocks, width: blockWidth, context: context)
        case .thematicBreak:
            blockHeight = ThematicBreakView.exactHeight(context: context)
        default:
            blockHeight = 0
        }

        return CGSize(width: blockWidth, height: blockHeight)
    }

    private static func needsTrailingSpacing(after index: Int, in blocks: [MarkdownBlock]) -> Bool {
        guard index + 1 < blocks.count else { return false }
        switch blocks[index + 1] {
        case .heading, .paragraph, .list:
            return true
        default:
            return false
        }
    }
}
#endif
