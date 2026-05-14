import MMMDCore

#if canImport(AppKit)
import AppKit

final class BlockquoteBlockView: NSView {
    init(blocks: [MarkdownBlock], context: RenderContext) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 10
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 0.5

        let indicator = NSView()
        indicator.wantsLayer = true
        indicator.layer?.backgroundColor = NSColor.secondaryLabelColor.cgColor
        indicator.translatesAutoresizingMaskIntoConstraints = false

        let textBlockView = TextBlockView(blocks: blocks, context: context, textColor: .secondaryLabelColor)
        textBlockView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(indicator)
        addSubview(textBlockView)
        NSLayoutConstraint.activate([
            indicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            indicator.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            indicator.widthAnchor.constraint(equalToConstant: 3),

            textBlockView.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 10),
            textBlockView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            textBlockView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textBlockView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
