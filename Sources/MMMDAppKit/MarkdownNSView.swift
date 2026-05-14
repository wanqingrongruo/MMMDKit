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

    private static var heightCache = NSCache<NSString, NSNumber>()
    private static let sizingView: MarkdownNSView = {
        let view = MarkdownNSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public static func estimatedHeight(for document: MarkdownDocument, width: CGFloat, configuration: MarkdownConfiguration) -> CGFloat {
        let cacheKey = "\(document.source.hashValue)_\(width)" as NSString
        if let cached = heightCache.object(forKey: cacheKey) {
            return CGFloat(cached.floatValue)
        }
        
        sizingView.configuration = configuration
        sizingView.render(document)
        
        let widthConstraint = sizingView.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.isActive = true
        sizingView.layoutSubtreeIfNeeded()
        
        let totalHeight = ceil(sizingView.fittingSize.height)
        widthConstraint.isActive = false
        
        heightCache.setObject(NSNumber(value: Float(totalHeight)), forKey: cacheKey)
        return totalHeight
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

        var currentBlockIndex = 0

        func flushTextBlocks() {
            guard !textBlocks.isEmpty else { return }
            let cacheKey = "\(document.source.hashValue)_\(currentBlockIndex)"
            let combinedView = TextBlockView(blocks: textBlocks, context: context, cacheKey: cacheKey)
            combinedView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            stackView.addArrangedSubview(combinedView)
            currentBlockIndex += textBlocks.count
            textBlocks.removeAll()
        }

        for block in document.blocks {
            switch block {
            case .heading, .paragraph, .blockquote, .list:
                textBlocks.append(block)
                continue
            default:
                flushTextBlocks()
            }

            let blockView: NSView
            switch block {
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
