import Foundation
import MMMDCore
@_exported import MMMDStreaming

#if canImport(AppKit)
import AppKit

/// macOS 的原生 Markdown 渲染视图。
///
/// `MarkdownNSView` 使用 AppKit 组件渲染 Markdown 文档。它自身不创建滚动容器，
/// 因此适合嵌入聊天气泡、`NSScrollView` 或 SwiftUI `NSViewRepresentable` 中。
open class MarkdownNSView: NSView {
    /// 当前视图最近一次渲染的 Markdown 文档。
    public private(set) var document = MarkdownDocument(blocks: [])
    /// 渲染配置。请在调用 `render(_:)` 或 `startStreaming(...)` 前设置。
    public var configuration = MarkdownConfiguration()

    private var renderItems: [MarkdownRenderItem] = []
    private var itemViews: [NSView] = []
    private var cachedLayout: AppKitMarkdownLayout?
    private var streamingSession: StreamingMarkdownSession?
    private var streamingStableBlockCount: Int?
    private var lastLaidOutWidth: CGFloat = 0

    open override var isFlipped: Bool {
        true
    }

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
        postsFrameChangedNotifications = true
    }

    /// 渲染一个完整的 Markdown 文档。
    ///
    /// 该方法会应用 `configuration.plugins`，并使用统一的 AppKit 渲染计划重建块视图。
    open func render(_ document: MarkdownDocument) {
        render(document, streamingStableBlockCount: nil)
    }

    private func render(_ document: MarkdownDocument, streamingStableBlockCount: Int?) {
        self.streamingStableBlockCount = streamingStableBlockCount
        self.document = (try? configuration.transformedDocument(document)) ?? document
        renderItems = MarkdownRenderPlanBuilder.makeItems(from: self.document)
        rebuildViews()
        cachedLayout = nil
        setAccessibilityLabel(MarkdownTextExtractor.plainText(from: self.document))
        invalidateIntrinsicContentSize()
        needsLayout = true
    }

    open override var intrinsicContentSize: NSSize {
        let width = measurementWidth
        let layout = layoutForWidth(width)
        return NSSize(width: NSView.noIntrinsicMetric, height: layout.size.height)
    }

    open override func layout() {
        super.layout()
        let width = measurementWidth
        let widthChanged = abs(lastLaidOutWidth - width) >= 0.5
        let layout = layoutForWidth(width)
        cachedLayout = layout
        lastLaidOutWidth = width

        for (index, layoutItem) in layout.items.enumerated() where index < itemViews.count {
            itemViews[index].frame = layoutItem.frame
            itemViews[index].needsLayout = true
            itemViews[index].layoutSubtreeIfNeeded()
        }
        if widthChanged {
            invalidateIntrinsicContentSize()
        }
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

    public static func estimatedHeight(for document: MarkdownDocument, width: CGFloat, configuration: MarkdownConfiguration) -> CGFloat {
        let transformedDocument = (try? configuration.transformedDocument(document)) ?? document
        let context = AppKitMarkdownContextBuilder.makeContext(configuration: configuration)
        let items = MarkdownRenderPlanBuilder.makeItems(from: transformedDocument)
        return AppKitMarkdownBlockMeasurer.layout(
            items: items,
            fittingWidth: max(1, width),
            context: context
        ).size.height
    }

    private var measurementWidth: CGFloat {
        max(1, bounds.width)
    }

    private func layoutForWidth(_ width: CGFloat) -> AppKitMarkdownLayout {
        if let cachedLayout, abs(lastLaidOutWidth - width) < 0.5 {
            return cachedLayout
        }
        let context = AppKitMarkdownContextBuilder.makeContext(configuration: configuration)
        return AppKitMarkdownBlockMeasurer.layout(
            items: renderItems,
            fittingWidth: width,
            context: context
        )
    }

    private func rebuildViews() {
        itemViews.forEach { $0.removeFromSuperview() }
        let context = AppKitMarkdownContextBuilder.makeContext(configuration: configuration)
        itemViews = renderItems.map {
            let view = AppKitMarkdownBlockViewFactory.makeView(
                for: $0,
                documentSourceHash: document.source.hashValue,
                context: context,
                streamingStableBlockCount: streamingStableBlockCount
            )
            view.autoresizingMask = []
            addSubview(view)
            return view
        }
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
