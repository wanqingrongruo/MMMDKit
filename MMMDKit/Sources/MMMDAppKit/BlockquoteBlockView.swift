import MMMDCore

#if canImport(AppKit)
import AppKit

final class BlockquoteBlockView: NSView {
    private static let lineWidth: CGFloat = 3
    private static let contentGap: CGFloat = 12
    private static let verticalPadding: CGFloat = 8

    init(blocks: [MarkdownBlock], context: RenderContext) {
        super.init(frame: .zero)
        setAccessibilityElement(false)

        let line = NSView()
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor
        line.layer?.cornerRadius = Self.lineWidth / 2
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)

        let contentView = TextBlockView(blocks: blocks, context: context, textColor: .secondaryLabelColor)
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
