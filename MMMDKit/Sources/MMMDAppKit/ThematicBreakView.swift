import MMMDCore

#if canImport(AppKit)
import AppKit

final class ThematicBreakView: NSView {
    static func exactHeight(context: RenderContext) -> CGFloat {
        1
    }

    init(context: RenderContext) {
        super.init(frame: .zero)
        setAccessibilityElement(true)
        setAccessibilityLabel("分割线")

        let line = NSView()
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.18).cgColor
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)

        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.centerYAnchor.constraint(equalTo: centerYAnchor),
            line.heightAnchor.constraint(equalToConstant: 1),
            heightAnchor.constraint(equalToConstant: Self.exactHeight(context: context))
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
