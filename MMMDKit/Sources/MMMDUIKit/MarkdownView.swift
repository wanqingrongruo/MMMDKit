import Foundation
import MMMDCore
@_exported import MMMDStreaming

#if canImport(UIKit)
import UIKit

open class MarkdownView: UIView {
    public private(set) var document = MarkdownDocument(blocks: [])
    public var configuration = MarkdownConfiguration()
    private let stackView = UIStackView()
    private var streamingSession: StreamingMarkdownSession?

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

    @discardableResult
    open func startStreaming(
        parser: MarkdownParser,
        parseOptions: ParseOptions = .init(),
        updateInterval: TimeInterval = 0.08,
        onUpdate: ((MarkdownRenderDiff) -> Void)? = nil
    ) -> StreamingMarkdownSession {
        let session = StreamingMarkdownSession(
            parser: parser,
            parseOptions: parseOptions,
            updateInterval: updateInterval,
            deliveryQueue: .main
        )
        session.onUpdate = { [weak self] diff in
            guard let self else { return }
            self.render(diff.document)
            onUpdate?(diff)
        }
        streamingSession = session
        render(MarkdownDocument(blocks: []))
        return session
    }

    open func appendStreamingText(_ delta: String) {
        streamingSession?.append(delta)
    }

    open func finishStreaming() {
        streamingSession?.finish()
    }

    open func resetStreaming() {
        streamingSession?.reset()
        render(MarkdownDocument(blocks: []))
    }

    private static var heightCache = NSCache<NSString, NSNumber>()
    private static let sizingView = MarkdownView()

    public static func estimatedHeight(for document: MarkdownDocument, width: CGFloat, configuration: MarkdownConfiguration) -> CGFloat {
        let cacheKey = "\(document.source.hashValue)_\(width)" as NSString
        if let cached = heightCache.object(forKey: cacheKey) {
            return CGFloat(cached.floatValue)
        }
        
        sizingView.configuration = configuration
        sizingView.render(document)
        
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let size = sizingView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        let totalHeight = ceil(size.height)
        heightCache.setObject(NSNumber(value: Float(totalHeight)), forKey: cacheKey)
        return totalHeight
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
            toolbarOptions: configuration.toolbarOptions,
            blockRendererRegistry: configuration.blockRendererRegistry,
            inlineRendererRegistry: configuration.inlineRendererRegistry,
            codeHighlighter: configuration.codeHighlighter,
            mathRenderer: configuration.mathRenderer,
            imageLoader: configuration.imageLoader,
            codeBlockMaximumWidth: configuration.codeBlockMaximumWidth
        )
        
        var textBlocks: [MarkdownBlock] = []
        
        var currentBlockIndex = 0
        
        func flushTextBlocks() {
            guard !textBlocks.isEmpty else { return }
            let cacheKey = "\(document.source.hashValue)_\(currentBlockIndex)"
            let combinedView = TextBlockView(blocks: textBlocks, context: context, cacheKey: cacheKey)
            stackView.addArrangedSubview(combinedView)
            currentBlockIndex += textBlocks.count
            textBlocks.removeAll()
        }

        for block in document.blocks {
            switch block {
            case .heading, .paragraph, .list:
                textBlocks.append(block)
                continue
            default:
                flushTextBlocks()
            }

            let blockView: UIView
            switch block {
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
            case .blockquote(let blocks):
                blockView = BlockquoteBlockView(blocks: blocks, context: context)
            case .thematicBreak:
                blockView = ThematicBreakView(context: context)
            default:
                currentBlockIndex += 1
                continue
            }
            blockView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            stackView.addArrangedSubview(blockView)
            currentBlockIndex += 1
        }
        flushTextBlocks()
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
