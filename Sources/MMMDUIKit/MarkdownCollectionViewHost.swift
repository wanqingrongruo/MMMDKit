import MMMDCore

#if canImport(UIKit)
import UIKit

open class MarkdownCollectionViewHost: UIView, UICollectionViewDataSource {
    private var document = MarkdownDocument(blocks: [])
    private var configuration = MarkdownConfiguration()
    private let collectionView: UICollectionView

    public override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeLayout())
        super.init(frame: frame)
        setupCollectionView()
    }

    public required init?(coder: NSCoder) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeLayout())
        super.init(coder: coder)
        setupCollectionView()
    }

    open func render(_ document: MarkdownDocument, configuration: MarkdownConfiguration = .init()) {
        self.configuration = configuration
        self.document = (try? configuration.transformedDocument(document)) ?? document
        collectionView.reloadData()
    }

    @available(*, deprecated, renamed: "render(_:configuration:)")
    open func haorender(_ document: MarkdownDocument, configuration: MarkdownConfiguration = .init()) {
        render(document, configuration: configuration)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        document.blocks.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BlockCell.reuseIdentifier, for: indexPath) as? BlockCell ?? BlockCell()
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
        cell.host(blockView(for: document.blocks[indexPath.item], context: context))
        return cell
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.register(BlockCell.self, forCellWithReuseIdentifier: BlockCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private static func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = MarkdownTheme.default.spacing.blockSpacing
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func blockView(for block: MarkdownBlock, context: RenderContext) -> UIView {
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
            return CollectionMaxWidthBlockContainer(
                contentView: CodeBlockView(codeBlock: codeBlock, context: context),
                maximumWidth: context.codeBlockMaximumWidth.map { CGFloat($0) }
            )
        case .table(let table):
            let tableView = TableBlockView(table: table, context: context)
            return CollectionShrinkWrappedBlockContainer(
                contentView: tableView,
                preferredWidth: tableView.preferredContentWidth
            )
        case .math(let mathBlock):
            return MathBlockView(mathBlock: mathBlock, context: context)
        case .html(let htmlBlock):
            return HTMLBlockView(htmlBlock: htmlBlock, context: context)
        case .image(let imageBlock):
            return ImageBlockView(imageBlock: imageBlock, context: context)
        default:
            let label = UILabel()
            label.numberOfLines = 0
            label.text = MarkdownTextExtractor.plainText(from: block)
            return label
        }
    }
}

private final class CollectionMaxWidthBlockContainer: UIView {
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

private final class CollectionShrinkWrappedBlockContainer: UIView {
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

private final class BlockCell: UICollectionViewCell {
    static let reuseIdentifier = "MMMDUIKit.BlockCell"
    private var hostedView: UIView?
    private var activeConstraints: [NSLayoutConstraint] = []

    func host(_ view: UIView) {
        NSLayoutConstraint.deactivate(activeConstraints)
        activeConstraints.removeAll()
        hostedView?.removeFromSuperview()
        hostedView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        let bottom = view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottom.priority = .defaultHigh
        activeConstraints = [
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            bottom,
            view.widthAnchor.constraint(equalTo: contentView.widthAnchor)
        ]
        NSLayoutConstraint.activate(activeConstraints)
        setNeedsLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        NSLayoutConstraint.deactivate(activeConstraints)
        activeConstraints.removeAll()
        hostedView?.removeFromSuperview()
        hostedView = nil
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let targetSize = CGSize(width: layoutAttributes.size.width, height: UIView.layoutFittingCompressedSize.height)
        let size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        attributes.size = CGSize(width: layoutAttributes.size.width, height: ceil(size.height))
        return attributes
    }
}
#endif
