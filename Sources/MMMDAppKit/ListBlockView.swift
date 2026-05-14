import MMMDCore

#if canImport(AppKit)
import AppKit

final class ListBlockView: NSStackView {
    init(list: ListBlock, context: RenderContext) {
        super.init(frame: .zero)
        orientation = .vertical
        alignment = .leading
        spacing = 6
        setAccessibilityElement(false)

        for (index, item) in list.items.enumerated() {
            addArrangedSubview(Self.row(marker: Self.marker(for: list.style, index: index), item: item, context: context))
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func row(marker: String, item: ListItem, context: RenderContext) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8

        let markerLabel = NSTextField(labelWithString: marker)
        markerLabel.font = .preferredFont(forTextStyle: .body)
        markerLabel.textColor = .secondaryLabelColor
        markerLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true

        let contentLabel = TextBlockView(blocks: item.blocks, context: context)
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        row.addArrangedSubview(markerLabel)
        row.addArrangedSubview(contentLabel)
        return row
    }

    private static func marker(for style: ListBlock.Style, index: Int) -> String {
        switch style {
        case .ordered(let start):
            return "\(start + index)."
        case .unordered:
            return "•"
        case .task:
            return "□"
        }
    }
}
#endif
