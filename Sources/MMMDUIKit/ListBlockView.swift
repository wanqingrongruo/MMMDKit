import MMMDCore

#if canImport(UIKit)
import UIKit

final class ListBlockView: UIStackView {
    init(list: ListBlock, context: RenderContext) {
        super.init(frame: .zero)
        axis = .vertical
        spacing = 6
        isAccessibilityElement = false

        for (index, item) in list.items.enumerated() {
            addArrangedSubview(Self.row(marker: Self.marker(for: list.style, index: index), item: item))
        }
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func row(marker: String, item: ListItem) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8

        let markerLabel = UILabel()
        markerLabel.font = .preferredFont(forTextStyle: .body)
        markerLabel.textColor = .secondaryLabel
        markerLabel.text = marker
        markerLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true

        let contentLabel = UILabel()
        contentLabel.numberOfLines = 0
        contentLabel.font = .preferredFont(forTextStyle: .body)
        contentLabel.textColor = .label
        contentLabel.text = item.blocks.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "\n")
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentLabel.isAccessibilityElement = true
        contentLabel.accessibilityLabel = "\(marker) \(contentLabel.text ?? "")"

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
