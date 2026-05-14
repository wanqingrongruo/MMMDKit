import Foundation
import MMMDCore

#if canImport(AppKit)
import AppKit

open class MarkdownNSView: NSView {
    public private(set) var document = MarkdownDocument(blocks: [])
    public var configuration = MarkdownConfiguration()
    private let stackView = NSStackView()

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        setAccessibilityElement(false)
        stackView.orientation = .vertical
        stackView.alignment = .width
        stackView.spacing = configuration.theme.spacing.blockSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    open func render(_ document: MarkdownDocument) {
        self.document = (try? configuration.transformedDocument(document)) ?? document
        rebuildBlocks()
        setAccessibilityLabel(MarkdownTextExtractor.plainText(from: self.document))
        needsLayout = true
    }

    public static func estimatedHeight(for document: MarkdownDocument, width: CGFloat, configuration: MarkdownConfiguration) -> CGFloat {
        let blockHeights = document.blocks.map { block -> CGFloat in
            switch block {
            case .heading:
                return max(24, textHeight(MarkdownTextExtractor.plainText(from: block), width: width, font: .preferredFont(forTextStyle: .headline)))
            case .paragraph:
                return max(20, textHeight(MarkdownTextExtractor.plainText(from: block), width: width, font: .preferredFont(forTextStyle: .body)))
            case .list(let list):
                return list.items.map { item in
                    textHeight(item.blocks.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "\n"), width: max(1, width - 32), font: .preferredFont(forTextStyle: .body)) + 6
                }.reduce(0, +)
            case .blockquote:
                return max(40, textHeight(MarkdownTextExtractor.plainText(from: block), width: max(1, width - 41), font: .preferredFont(forTextStyle: .body)) + 20)
            case .code(let codeBlock):
                let lineCount = max(1, codeBlock.content.split(separator: "\n", omittingEmptySubsequences: false).count)
                return CGFloat(lineCount) * 18 + 58
            case .table(let table):
                return CGFloat(max(1, table.rows.count + (table.header.isEmpty ? 0 : 1))) * 42 + 50
            case .math:
                return max(40, textHeight(MarkdownTextExtractor.plainText(from: block), width: max(1, width - 24), font: .preferredFont(forTextStyle: .body)) + 20)
            case .html:
                return 120
            case .image:
                return 180
            default:
                return max(20, textHeight(MarkdownTextExtractor.plainText(from: block), width: width, font: .preferredFont(forTextStyle: .body)))
            }
        }
        let spacing = max(0, CGFloat(max(0, document.blocks.count - 1)) * configuration.theme.spacing.blockSpacing)
        return max(1, blockHeights.reduce(0, +) + spacing)
    }

    private static func textHeight(_ text: String, width: CGFloat, font: NSFont) -> CGFloat {
        let rect = (text as NSString).boundingRect(
            with: NSSize(width: max(1, width), height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return ceil(rect.height)
    }

    private func rebuildBlocks() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

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

        var textBlocks: [MarkdownBlock] = []

        func flushTextBlocks() {
            guard !textBlocks.isEmpty else { return }
            let combinedView = TextBlockView(blocks: textBlocks, context: context)
            combinedView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            stackView.addArrangedSubview(combinedView)
            textBlocks.removeAll()
        }

        for block in document.blocks {
            switch block {
            case .heading, .paragraph:
                textBlocks.append(block)
                continue
            default:
                flushTextBlocks()
            }

            let blockView: NSView
            switch block {
            case .list(let list):
                blockView = ListBlockView(list: list, context: context)
            case .blockquote(let blocks):
                blockView = BlockquoteBlockView(blocks: blocks, context: context)
            case .code(let codeBlock):
                blockView = MarkdownNSMaxWidthBlockContainer(
                    contentView: CodeBlockView(codeBlock: codeBlock, context: context),
                    maximumWidth: context.codeBlockMaximumWidth.map { CGFloat($0) }
                )
            case .table(let table):
                let tableView = TableBlockView(table: table, context: context)
                blockView = MarkdownNSShrinkWrappedBlockContainer(
                    contentView: tableView,
                    preferredWidth: tableView.preferredContentWidth
                )
            case .math(let mathBlock):
                blockView = MathBlockView(mathBlock: mathBlock, context: context)
            case .html(let htmlBlock):
                blockView = HTMLBlockView(htmlBlock: htmlBlock, context: context)
            case .image(let imageBlock):
                blockView = ImageBlockView(imageBlock: imageBlock, context: context)
            default:
                continue
            }
            blockView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            stackView.addArrangedSubview(blockView)
        }
        flushTextBlocks()
    }
}

private final class MarkdownNSMaxWidthBlockContainer: NSView {
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

private final class MarkdownNSShrinkWrappedBlockContainer: NSView {
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
#else
public final class MarkdownNSView {
    public private(set) var document = MarkdownDocument(blocks: [])
    public var configuration = MarkdownConfiguration()

    public init() {}

    public func render(_ document: MarkdownDocument) {
        self.document = document
    }
}
#endif
