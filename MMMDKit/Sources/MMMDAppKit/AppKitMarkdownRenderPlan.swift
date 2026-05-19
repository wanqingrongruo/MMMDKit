import MMMDCore

#if canImport(AppKit)
import AppKit

enum MarkdownRenderItem {
    case text(blocks: [MarkdownBlock], startBlockIndex: Int)
    case block(MarkdownBlock, blockIndex: Int)

    var startBlockIndex: Int {
        switch self {
        case .text(_, let startBlockIndex):
            return startBlockIndex
        case .block(_, let blockIndex):
            return blockIndex
        }
    }
}

struct AppKitMarkdownLayoutItem {
    let renderItem: MarkdownRenderItem
    let frame: CGRect
}

struct AppKitMarkdownLayout {
    let items: [AppKitMarkdownLayoutItem]
    let size: CGSize
}

enum AppKitMarkdownContextBuilder {
    static func makeContext(configuration: MarkdownConfiguration) -> RenderContext {
        RenderContext(
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
    }
}

enum MarkdownRenderPlanBuilder {
    static func makeItems(from document: MarkdownDocument) -> [MarkdownRenderItem] {
        var items: [MarkdownRenderItem] = []
        var textBlocks: [MarkdownBlock] = []
        var textStartIndex = 0

        func flushTextBlocks() {
            guard !textBlocks.isEmpty else { return }
            items.append(.text(blocks: textBlocks, startBlockIndex: textStartIndex))
            textBlocks.removeAll()
        }

        for (index, block) in document.blocks.enumerated() {
            switch block {
            case .heading, .paragraph, .list:
                if textBlocks.isEmpty {
                    textStartIndex = index
                }
                textBlocks.append(block)
            default:
                flushTextBlocks()
                items.append(.block(block, blockIndex: index))
            }
        }

        flushTextBlocks()
        return items
    }
}

enum AppKitMarkdownBlockMeasurer {
    static func layout(
        items: [MarkdownRenderItem],
        fittingWidth width: CGFloat,
        context: RenderContext
    ) -> AppKitMarkdownLayout {
        let contentWidth = max(1, width)
        var y: CGFloat = 0
        var layoutItems: [AppKitMarkdownLayoutItem] = []

        for item in items {
            let itemSize = measuredSize(for: item, fittingWidth: contentWidth, context: context)
            if !layoutItems.isEmpty {
                y += context.theme.spacing.blockSpacing
            }
            let frame = CGRect(
                x: 0,
                y: y,
                width: min(contentWidth, itemSize.width),
                height: itemSize.height
            )
            layoutItems.append(AppKitMarkdownLayoutItem(renderItem: item, frame: frame))
            y = frame.maxY
        }

        return AppKitMarkdownLayout(
            items: layoutItems,
            size: CGSize(width: contentWidth, height: ceil(y))
        )
    }

    static func measuredSize(
        for item: MarkdownRenderItem,
        fittingWidth width: CGFloat,
        context: RenderContext
    ) -> CGSize {
        switch item {
        case .text(let blocks, _):
            return CGSize(
                width: max(1, width),
                height: TextBlockView.estimatedHeight(for: blocks, width: width, context: context)
            )
        case .block(let block, _):
            return measuredSize(for: block, fittingWidth: width, context: context)
        }
    }

    private static func measuredSize(
        for block: MarkdownBlock,
        fittingWidth width: CGFloat,
        context: RenderContext
    ) -> CGSize {
        let contentWidth = max(1, width)
        switch block {
        case .code(let codeBlock):
            let blockWidth = constrainedWidth(contentWidth, maximumWidth: context.codeBlockMaximumWidth)
            return CGSize(
                width: blockWidth,
                height: CodeBlockView.height(for: codeBlock, width: blockWidth, context: context)
            )
        case .table(let table):
            let preferredWidth = TableBlockView.preferredWidth(for: table)
            return CGSize(
                width: min(contentWidth, preferredWidth),
                height: TableBlockView.height(for: table)
            )
        case .math(let mathBlock):
            return CGSize(
                width: contentWidth,
                height: mathHeight(for: mathBlock, width: contentWidth)
            )
        case .html(let htmlBlock):
            return CGSize(
                width: contentWidth,
                height: htmlHeight(for: htmlBlock, width: contentWidth)
            )
        case .image:
            return CGSize(width: contentWidth, height: 200)
        case .blockquote(let blocks):
            let quoteContentWidth = max(1, contentWidth - 15)
            let height = TextBlockView.estimatedHeight(
                for: blocks,
                width: quoteContentWidth,
                context: context,
                textColor: .secondaryLabelColor
            ) + 16
            return CGSize(width: contentWidth, height: max(36, height))
        case .thematicBreak:
            return CGSize(width: contentWidth, height: ThematicBreakView.exactHeight(context: context))
        default:
            return CGSize(width: contentWidth, height: textHeight(
                MarkdownTextExtractor.plainText(from: block),
                width: contentWidth,
                font: .preferredFont(forTextStyle: .body)
            ))
        }
    }

    private static func constrainedWidth(_ width: CGFloat, maximumWidth: Double?) -> CGFloat {
        guard let maximumWidth, maximumWidth > 0 else { return width }
        return min(width, CGFloat(maximumWidth))
    }

    private static func textHeight(_ text: String, width: CGFloat, font: NSFont) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let rect = (text as NSString).boundingRect(
            with: NSSize(width: max(1, width), height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return ceil(rect.height)
    }

    private static func mathHeight(for mathBlock: MathBlock, width: CGFloat) -> CGFloat {
        let font = NSFont.preferredFont(forTextStyle: .body)
        let baseHeight = textHeight(mathBlock.latex, width: max(1, width - 24), font: font)
        return max(42, baseHeight + 20)
    }

    private static func htmlHeight(for htmlBlock: HTMLBlock, width: CGFloat) -> CGFloat {
        max(120, textHeight(MarkdownTextExtractor.plainText(from: .html(htmlBlock)), width: width, font: .preferredFont(forTextStyle: .body)) + 24)
    }
}

enum AppKitMarkdownBlockViewFactory {
    static func makeView(
        for item: MarkdownRenderItem,
        documentSourceHash: Int,
        context: RenderContext,
        streamingStableBlockCount: Int?
    ) -> NSView {
        switch item {
        case .text(let blocks, let startBlockIndex):
            let contentHash = blocks.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "\n").hashValue
            let cacheKey = "\(documentSourceHash)_\(startBlockIndex)_\(contentHash)"
            let view = TextBlockView(blocks: blocks, context: context, cacheKey: cacheKey)
            view.setContentCompressionResistancePriority(.required, for: .vertical)
            return view
        case .block(let block, let blockIndex):
            return makeView(
                for: block,
                blockIndex: blockIndex,
                context: context,
                streamingStableBlockCount: streamingStableBlockCount
            )
        }
    }

    private static func makeView(
        for block: MarkdownBlock,
        blockIndex: Int,
        context: RenderContext,
        streamingStableBlockCount: Int?
    ) -> NSView {
        switch block {
        case .code(let codeBlock):
            let highlightsCode = streamingStableBlockCount.map { blockIndex < $0 } ?? true
            return AppKitMaxWidthBlockContainer(
                contentView: CodeBlockView(codeBlock: codeBlock, context: context, highlightsCode: highlightsCode),
                maximumWidth: context.codeBlockMaximumWidth.map { CGFloat($0) }
            )
        case .table(let table):
            let tableView = TableBlockView(table: table, context: context)
            return AppKitShrinkWrappedBlockContainer(
                contentView: tableView,
                preferredWidth: tableView.preferredContentWidth
            )
        case .math(let mathBlock):
            return MathBlockView(mathBlock: mathBlock, context: context)
        case .html(let htmlBlock):
            return HTMLBlockView(htmlBlock: htmlBlock, context: context)
        case .image(let imageBlock):
            return ImageBlockView(imageBlock: imageBlock, context: context)
        case .blockquote(let blocks):
            return BlockquoteBlockView(blocks: blocks, context: context)
        case .thematicBreak:
            return ThematicBreakView(context: context)
        default:
            return NSTextField(wrappingLabelWithString: MarkdownTextExtractor.plainText(from: block))
        }
    }
}

final class AppKitMaxWidthBlockContainer: NSView {
    init(contentView: NSView, maximumWidth: CGFloat?) {
        super.init(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        let fillWidth = contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
        fillWidth.priority = .defaultHigh

        var constraints = [
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            fillWidth
        ]
        if let maximumWidth, maximumWidth > 0 {
            constraints.append(contentView.widthAnchor.constraint(lessThanOrEqualToConstant: maximumWidth))
        }
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

final class AppKitShrinkWrappedBlockContainer: NSView {
    init(contentView: NSView, preferredWidth: CGFloat) {
        super.init(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        let preferredWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: preferredWidth)
        preferredWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            preferredWidthConstraint
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
