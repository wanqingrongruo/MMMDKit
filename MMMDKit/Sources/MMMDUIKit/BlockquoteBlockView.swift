import MMMDCore

#if canImport(UIKit)
import UIKit

public final class BlockquoteBlockView: UIView {
    private static let lineWidth: CGFloat = 3
    private static let contentGap: CGFloat = 12
    private static let verticalPadding: CGFloat = 8

    public static func exactHeight(for blocks: [MarkdownBlock], width: CGFloat, context: RenderContext) -> CGFloat {
        let contentWidth = max(1, width - lineWidth - contentGap)
        let attr = TextBlockView.attributedString(
            for: blocks,
            context: context,
            textColor: .secondaryLabel,
            listLevel: 0,
            blockquoteLevel: 0
        )
        let textStorage = NSTextStorage(attributedString: attr)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: contentWidth, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)
        return ceil(layoutManager.usedRect(for: textContainer).height) + verticalPadding * 2
    }

    public init(blocks: [MarkdownBlock], context: RenderContext) {
        super.init(frame: .zero)
        mmmdSuppressTextViewAttachmentSelection()
        isAccessibilityElement = false

        let line = UIView()
        line.backgroundColor = UIColor.separator.withAlphaComponent(0.35)
        line.layer.cornerRadius = Self.lineWidth / 2
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)

        let contentView = TextBlockView(blocks: blocks, context: context, textColor: .secondaryLabel)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.topAnchor.constraint(equalTo: topAnchor, constant: Self.verticalPadding),
            line.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.verticalPadding),
            line.widthAnchor.constraint(equalToConstant: Self.lineWidth),

            contentView.leadingAnchor.constraint(equalTo: line.trailingAnchor, constant: Self.contentGap),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: Self.verticalPadding),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.verticalPadding)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
