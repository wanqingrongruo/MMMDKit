import MMMDCore

#if canImport(AppKit)
import AppKit

open class MarkdownCollectionViewHost: NSView, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private var document = MarkdownDocument(blocks: [])
    private var configuration = MarkdownConfiguration()
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
        self.document = document
        self.configuration = configuration
        collectionLayout.invalidateLayout()
        collectionView.reloadData()
    }

    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        document.blocks.count
    }

    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: BlockItem.identifier, for: indexPath) as? BlockItem ?? BlockItem()
        let context = RenderContext(
            theme: configuration.theme,
            actions: configuration.actions,
            codeHighlighter: configuration.codeHighlighter,
            mathRenderer: configuration.mathRenderer,
            imageLoader: configuration.imageLoader,
            codeBlockMaximumWidth: configuration.codeBlockMaximumWidth
        )
        item.host(blockView(for: document.blocks[indexPath.item], context: context))
        return item
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

    open override func layout() {
        super.layout()
        collectionLayout.invalidateLayout()
    }

    public func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        let visibleWidth = collectionView.enclosingScrollView?.contentView.bounds.width ?? collectionView.bounds.width
        let width = max(1, visibleWidth)
        let height = height(for: document.blocks[indexPath.item], width: width)
        return NSSize(width: width, height: height)
    }

    private func blockView(for block: MarkdownBlock, context: RenderContext) -> NSView {
        switch block {
        case .heading(let level, let content):
            return HeadingBlockView(level: level, content: content, context: context)
        case .paragraph(let content):
            return ParagraphBlockView(content: content, context: context)
        case .list(let list):
            return ListBlockView(list: list, context: context)
        case .blockquote(let blocks):
            return BlockquoteBlockView(blocks: blocks, context: context)
        case .code(let codeBlock):
            return MaxWidthBlockContainer(
                contentView: CodeBlockView(codeBlock: codeBlock, context: context),
                maximumWidth: context.codeBlockMaximumWidth.map { CGFloat($0) }
            )
        case .table(let table):
            return TableBlockView(table: table, context: context)
        case .math(let mathBlock):
            return MathBlockView(mathBlock: mathBlock, context: context)
        case .html(let htmlBlock):
            return HTMLBlockView(htmlBlock: htmlBlock, context: context)
        case .image(let imageBlock):
            return ImageBlockView(imageBlock: imageBlock, context: context)
        default:
            return NSTextField(wrappingLabelWithString: MarkdownTextExtractor.plainText(from: block))
        }
    }

    private func height(for block: MarkdownBlock, width: CGFloat) -> CGFloat {
        let availableWidth = max(1, width - 8)
        switch block {
        case .heading:
            return max(34, textHeight(MarkdownTextExtractor.plainText(from: block), width: availableWidth, font: .preferredFont(forTextStyle: .headline)) + 8)
        case .paragraph:
            return max(28, textHeight(MarkdownTextExtractor.plainText(from: block), width: availableWidth, font: .preferredFont(forTextStyle: .body)) + 8)
        case .list(let list):
            let rowHeights = list.items.map { item in
                textHeight(item.blocks.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "\n"), width: max(1, availableWidth - 40), font: .preferredFont(forTextStyle: .body)) + 6
            }
            return max(32, rowHeights.reduce(0, +) + 8)
        case .blockquote:
            return max(36, textHeight(MarkdownTextExtractor.plainText(from: block), width: max(1, availableWidth - 16), font: .preferredFont(forTextStyle: .body)) + 12)
        case .code(let codeBlock):
            let lineCount = max(1, codeBlock.content.split(separator: "\n", omittingEmptySubsequences: false).count)
            return CGFloat(lineCount) * 18 + 58
        case .table(let table):
            return TableBlockView.height(for: table)
        case .math:
            return max(38, textHeight(MarkdownTextExtractor.plainText(from: block), width: availableWidth, font: .preferredFont(forTextStyle: .body)) + 12)
        case .html:
            return 120
        case .image:
            return 180
        default:
            return max(28, textHeight(MarkdownTextExtractor.plainText(from: block), width: availableWidth, font: .preferredFont(forTextStyle: .body)) + 8)
        }
    }

    private func textHeight(_ text: String, width: CGFloat, font: NSFont) -> CGFloat {
        let rect = (text as NSString).boundingRect(
            with: NSSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return ceil(rect.height)
    }
}

private final class MaxWidthBlockContainer: NSView {
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
            blockView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blockView.topAnchor.constraint(equalTo: view.topAnchor),
            bottom,
            blockView.widthAnchor.constraint(equalTo: view.widthAnchor)
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
        guard let collectionView else {
            return
        }
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
