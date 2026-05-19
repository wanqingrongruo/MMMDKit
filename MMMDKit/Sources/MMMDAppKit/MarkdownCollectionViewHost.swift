import MMMDCore

#if canImport(AppKit)
import AppKit

/// 适合长文档的 AppKit Markdown 滚动容器。
///
/// 与 `MarkdownNSView` 使用同一套 render plan 和测量器；区别在于这里用 `NSCollectionView`
/// 承载每个 block item，适合未来做长文档虚拟化。
open class MarkdownCollectionViewHost: NSView, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private var document = MarkdownDocument(blocks: [])
    private var renderItems: [MarkdownRenderItem] = []
    private var configuration = MarkdownConfiguration()
    private var cachedLayout: AppKitMarkdownLayout?
    private var cachedWidth: CGFloat = 0

    private let collectionView = NSCollectionView()
    private let scrollView = NSScrollView()
    private let collectionLayout = SingleColumnCollectionViewFlowLayout()

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupCollectionView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCollectionView()
    }

    open func render(_ document: MarkdownDocument, configuration: MarkdownConfiguration = .init()) {
        self.configuration = configuration
        self.document = (try? configuration.transformedDocument(document)) ?? document
        renderItems = MarkdownRenderPlanBuilder.makeItems(from: self.document)
        cachedLayout = nil
        collectionLayout.invalidateLayout()
        collectionView.reloadData()
    }

    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        renderItems.count
    }

    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: BlockItem.identifier, for: indexPath) as? BlockItem ?? BlockItem()
        let context = AppKitMarkdownContextBuilder.makeContext(configuration: configuration)
        let blockView = AppKitMarkdownBlockViewFactory.makeView(
            for: renderItems[indexPath.item],
            documentSourceHash: document.source.hashValue,
            context: context,
            streamingStableBlockCount: nil
        )
        item.host(blockView)
        return item
    }

    public func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        let width = contentWidth(for: collectionView)
        let layout = layoutForWidth(width)
        guard indexPath.item < layout.items.count else {
            return NSSize(width: width, height: 1)
        }
        return NSSize(width: width, height: layout.items[indexPath.item].frame.height)
    }

    open override func layout() {
        super.layout()
        cachedLayout = nil
        collectionLayout.invalidateLayout()
    }

    private func setupCollectionView() {
        collectionView.collectionViewLayout = collectionLayout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BlockItem.self, forItemWithIdentifier: BlockItem.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            collectionView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
        ])
    }

    private func contentWidth(for collectionView: NSCollectionView) -> CGFloat {
        max(1, collectionView.enclosingScrollView?.contentView.bounds.width ?? collectionView.bounds.width)
    }

    private func layoutForWidth(_ width: CGFloat) -> AppKitMarkdownLayout {
        if let cachedLayout, abs(cachedWidth - width) < 0.5 {
            return cachedLayout
        }
        let layout = AppKitMarkdownBlockMeasurer.layout(
            items: renderItems,
            fittingWidth: width,
            context: AppKitMarkdownContextBuilder.makeContext(configuration: configuration)
        )
        cachedLayout = layout
        cachedWidth = width
        return layout
    }
}

private final class BlockItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("MMMDAppKit.BlockItem")
    private var hostedView: NSView?
    private var activeConstraints: [NSLayoutConstraint] = []

    override func loadView() {
        view = NSView()
    }

    func host(_ blockView: NSView) {
        NSLayoutConstraint.deactivate(activeConstraints)
        activeConstraints.removeAll()
        hostedView?.removeFromSuperview()
        hostedView = blockView
        blockView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blockView)
        let bottom = blockView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottom.priority = .defaultHigh
        activeConstraints = [
            blockView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blockView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            blockView.topAnchor.constraint(equalTo: view.topAnchor),
            bottom
        ]
        NSLayoutConstraint.activate(activeConstraints)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        NSLayoutConstraint.deactivate(activeConstraints)
        activeConstraints.removeAll()
        hostedView?.removeFromSuperview()
        hostedView = nil
    }
}

private final class SingleColumnCollectionViewFlowLayout: NSCollectionViewFlowLayout {
    override init() {
        super.init()
        minimumLineSpacing = MarkdownTheme.default.spacing.blockSpacing
        minimumInteritemSpacing = 0
        sectionInset = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        minimumLineSpacing = MarkdownTheme.default.spacing.blockSpacing
        minimumInteritemSpacing = 0
        sectionInset = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        let visibleWidth = collectionView.enclosingScrollView?.contentView.bounds.width ?? collectionView.bounds.width
        let width = max(1, visibleWidth - sectionInset.left - sectionInset.right)
        estimatedItemSize = .zero
        itemSize = NSSize(width: width, height: 120)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
        true
    }

    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        super.layoutAttributesForElements(in: rect).map { attributes in
            forceSingleColumn(attributes.copy() as? NSCollectionViewLayoutAttributes ?? attributes)
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath) else {
            return nil
        }
        return forceSingleColumn(attributes.copy() as? NSCollectionViewLayoutAttributes ?? attributes)
    }

    private func forceSingleColumn(_ attributes: NSCollectionViewLayoutAttributes) -> NSCollectionViewLayoutAttributes {
        guard attributes.representedElementCategory == .item, let collectionView else {
            return attributes
        }
        let visibleWidth = collectionView.enclosingScrollView?.contentView.bounds.width ?? collectionView.bounds.width
        let width = max(1, visibleWidth - sectionInset.left - sectionInset.right)
        var frame = attributes.frame
        frame.origin.x = sectionInset.left
        frame.size.width = width
        attributes.frame = frame
        return attributes
    }
}
#endif
