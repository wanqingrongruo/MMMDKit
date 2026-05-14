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
            addArrangedSubview(Self.row(marker: Self.marker(for: list.style, index: index), item: item, context: context))
        }
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func row(marker: String, item: ListItem, context: RenderContext) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8

        let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .regular))
        
        let markerLabel = UILabel()
        markerLabel.font = font
        markerLabel.textColor = .secondaryLabel
        markerLabel.text = marker
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
