import MMMDCore

#if canImport(UIKit)
import UIKit

final class TableBlockView: UIScrollView {
    init(table: TableBlock, context: RenderContext) {
        super.init(frame: .zero)
        showsHorizontalScrollIndicator = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        if !table.header.isEmpty {
            stack.addArrangedSubview(Self.row(cells: table.header, isHeader: true))
        }
        for row in table.rows {
            stack.addArrangedSubview(Self.row(cells: row, isHeader: false))
        }

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor)
        ])
        isAccessibilityElement = true
        accessibilityLabel = "表格，\(table.header.count) 列，\(table.rows.count) 行"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func row(cells: [InlineContent], isHeader: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 0

        for cell in cells {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = isHeader ? .preferredFont(forTextStyle: .headline) : .preferredFont(forTextStyle: .body)
            label.textColor = .label
            label.text = MarkdownTextExtractor.plainText(from: cell)
            label.backgroundColor = isHeader ? .tertiarySystemBackground : .clear
            label.layer.borderColor = UIColor.separator.cgColor
            label.layer.borderWidth = 0.5
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
            row.addArrangedSubview(label)
        }

        return row
    }
}
#endif
