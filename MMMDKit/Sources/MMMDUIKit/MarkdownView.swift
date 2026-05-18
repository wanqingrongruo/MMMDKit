import Foundation
import MMMDCore
@_exported import MMMDStreaming

#if canImport(UIKit)
import UIKit

/// iOS/iPadOS 的原生 Markdown 渲染视图。
///
/// `MarkdownView` 使用 UIKit 组件渲染文本、代码块、表格、公式、图片等块级内容。
/// 对静态内容调用 `render(_:)`，对 AI 场景的增量输出可使用内置流式 API。
open class MarkdownView: UIView {
    /// 当前视图最近一次渲染的 Markdown 文档。
    public private(set) var document = MarkdownDocument(blocks: [])
    /// 渲染配置。请在调用 `render(_:)` 或 `startStreaming(...)` 前设置。
    public var configuration = MarkdownConfiguration()
    private let stackView = UIStackView()
    private var streamingSession: StreamingMarkdownSession?
    private var streamingStableBlockCount: Int?

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

    /// 渲染一个完整的 Markdown 文档。
    ///
    /// 该方法会应用 `configuration.plugins`，并重建内部 UIKit 视图层级。
    open func render(_ document: MarkdownDocument) {
        render(document, streamingStableBlockCount: nil)
    }

    private func render(_ document: MarkdownDocument, streamingStableBlockCount: Int?) {
        self.streamingStableBlockCount = streamingStableBlockCount
        self.document = (try? configuration.transformedDocument(document)) ?? document
        rebuildBlocks()
        accessibilityLabel = MarkdownTextExtractor.plainText(from: self.document)
        setNeedsLayout()
    }

    /// 启动视图内置的流式渲染会话。
    ///
    /// 启动后，外部可持续调用 `appendStreamingText(_:)` 追加上游文本。
    /// 视图会自动节流刷新，并在流式过程中避免对未稳定尾部代码块反复高亮。
    /// - Returns: 本次流式会话对象；高级场景可以保留它以直接调用底层 API。
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
            self.render(
                diff.document,
                streamingStableBlockCount: diff.phase == .streaming ? diff.stableBlockCount : nil
            )
            onUpdate?(diff)
        }
        streamingSession = session
        render(MarkdownDocument(blocks: []))
        return session
    }

    /// 向当前流式会话追加一段 Markdown 文本。
    open func appendStreamingText(_ delta: String) {
        streamingSession?.append(delta)
    }

    /// 结束当前流式会话，并触发最终完整渲染。
    open func finishStreaming() {
        streamingSession?.finish()
    }

    /// 重置当前流式会话，并清空视图内容。
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
                let highlightsCode = streamingStableBlockCount.map { currentBlockIndex < $0 } ?? true
                blockView = UIKitMaxWidthBlockContainer(
                    contentView: CodeBlockView(codeBlock: codeBlock, context: context, highlightsCode: highlightsCode),
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
