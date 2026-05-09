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
            addArrangedSubview(Self.row(marker: Self.marker(for: list.style, index: index), item: item))
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func row(marker: String, item: ListItem) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8

        let markerLabel = NSTextField(labelWithString: marker)
        markerLabel.font = .preferredFont(forTextStyle: .body)
        markerLabel.textColor = .secondaryLabelColor
        markerLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true

        let contentLabel = NSTextField(wrappingLabelWithString: item.blocks.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "\n"))
        contentLabel.font = .preferredFont(forTextStyle: .body)
        contentLabel.textColor = .labelColor
        contentLabel.setAccessibilityElement(true)
        contentLabel.setAccessibilityLabel("\(marker) \(contentLabel.stringValue)")

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
