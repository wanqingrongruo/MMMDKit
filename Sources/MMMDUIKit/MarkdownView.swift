import Foundation
import MMMDCore

#if canImport(UIKit)
import UIKit

open class MarkdownView: UIView {
    public private(set) var document = MarkdownDocument(blocks: [])
    public var configuration = MarkdownConfiguration()
    private let stackView = UIStackView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        isAccessibilityElement = false
        stackView.axis = .vertical
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
        accessibilityLabel = MarkdownTextExtractor.plainText(from: self.document)
        setNeedsLayout()
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

    private static func textHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: max(1, width), height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
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
            blockRendererRegistry: configuration.blockRendererRegistry,
            inlineRendererRegistry: configuration.inlineRendererRegistry,
            codeHighlighter: configuration.codeHighlighter,
            mathRenderer: configuration.mathRenderer,
            imageLoader: configuration.imageLoader,
            codeBlockMaximumWidth: configuration.codeBlockMaximumWidth
        )
        for block in document.blocks {
            let blockView: UIView
            switch block {
            case .heading(let level, let content):
                blockView = HeadingBlockView(level: level, content: content, context: context)
            case .paragraph(let content):
                blockView = ParagraphBlockView(content: content, context: context)
            case .list(let list):
                blockView = ListBlockView(list: list, context: context)
            case .blockquote(let blocks):
                blockView = BlockquoteBlockView(blocks: blocks, context: context)
            case .code(let codeBlock):
                blockView = UIKitMaxWidthBlockContainer(
                    contentView: CodeBlockView(codeBlock: codeBlock, context: context),
                    maximumWidth: context.codeBlockMaximumWidth.map { CGFloat($0) }
                )
            case .table(let table):
                let tableView = TableBlockView(table: table, context: context)
                blockView = UIKitShrinkWrappedBlockContainer(
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
    }
}

private final class UIKitMaxWidthBlockContainer: UIView {
    init(contentView: UIView, maximumWidth: CGFloat?) {
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

private final class UIKitShrinkWrappedBlockContainer: UIView {
    init(contentView: UIView, preferredWidth: CGFloat) {
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
public final class MarkdownView {
    public private(set) var document = MarkdownDocument(blocks: [])
    public var configuration = MarkdownConfiguration()

    public init() {}

    public func render(_ document: MarkdownDocument) {
        self.document = document
    }
}
#endif
