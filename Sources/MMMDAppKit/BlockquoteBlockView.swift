import MMMDCore

#if canImport(AppKit)
import AppKit

final class BlockquoteBlockView: NSView {
    init(blocks: [MarkdownBlock], context: RenderContext) {
        super.init(frame: .zero)

        let indicator = NSView()
        indicator.wantsLayer = true
        indicator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        indicator.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(wrappingLabelWithString: blocks.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "\n"))
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setAccessibilityElement(true)
        label.setAccessibilityLabel(label.stringValue)

        addSubview(indicator)
        addSubview(label)
        NSLayoutConstraint.activate([
            indicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicator.topAnchor.constraint(equalTo: topAnchor),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 3),

            label.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
