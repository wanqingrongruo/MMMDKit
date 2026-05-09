import MMMDCore

#if canImport(AppKit)
import AppKit

open class MarkdownCollectionViewHost: NSView, NSCollectionViewDataSource {
    private var document = MarkdownDocument(blocks: [])
    private var configuration = MarkdownConfiguration()
    private let collectionView = NSCollectionView()
    private let scrollView = NSScrollView()

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
            imageLoader: configuration.imageLoader
        )
        item.host(blockView(for: document.blocks[indexPath.item], context: context))
        return item
    }

    private func setupCollectionView() {
        let layout = NSCollectionViewFlowLayout()
        layout.estimatedItemSize = NSSize(width: 320, height: 44)
        layout.minimumLineSpacing = MarkdownTheme.default.spacing.blockSpacing
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.register(BlockItem.self, forItemWithIdentifier: BlockItem.identifier)

        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
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
            return CodeBlockView(codeBlock: codeBlock, context: context)
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
}

private final class BlockItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("MMMDAppKit.BlockItem")
    private var hostedView: NSView?

    override func loadView() {
        view = NSView()
    }

    func host(_ blockView: NSView) {
        hostedView?.removeFromSuperview()
        hostedView = blockView
        blockView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blockView)
        NSLayoutConstraint.activate([
            blockView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blockView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blockView.topAnchor.constraint(equalTo: view.topAnchor),
            blockView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blockView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hostedView?.removeFromSuperview()
        hostedView = nil
    }
}
#endif
