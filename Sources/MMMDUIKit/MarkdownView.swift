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
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }

    open func render(_ document: MarkdownDocument) {
        self.document = document
        rebuildBlocks()
        accessibilityLabel = MarkdownTextExtractor.plainText(from: document)
        setNeedsLayout()
    }

    private func rebuildBlocks() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let context = RenderContext(
            theme: configuration.theme,
            actions: configuration.actions,
            codeHighlighter: configuration.codeHighlighter,
            mathRenderer: configuration.mathRenderer,
            imageLoader: configuration.imageLoader,
            codeBlockMaximumWidth: configuration.codeBlockMaximumWidth
        )
        for block in document.blocks {
            switch block {
            case .heading(let level, let content):
                stackView.addArrangedSubview(HeadingBlockView(level: level, content: content, context: context))
            case .paragraph(let content):
                stackView.addArrangedSubview(ParagraphBlockView(content: content, context: context))
            case .list(let list):
                stackView.addArrangedSubview(ListBlockView(list: list, context: context))
            case .blockquote(let blocks):
                stackView.addArrangedSubview(BlockquoteBlockView(blocks: blocks, context: context))
            case .code(let codeBlock):
                stackView.addArrangedSubview(CodeBlockView(codeBlock: codeBlock, context: context))
            case .table(let table):
                stackView.addArrangedSubview(TableBlockView(table: table, context: context))
            case .math(let mathBlock):
                stackView.addArrangedSubview(MathBlockView(mathBlock: mathBlock, context: context))
            case .html(let htmlBlock):
                stackView.addArrangedSubview(HTMLBlockView(htmlBlock: htmlBlock, context: context))
            case .image(let imageBlock):
                stackView.addArrangedSubview(ImageBlockView(imageBlock: imageBlock, context: context))
            default:
                continue
            }
        }
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
