import MMMDCore

#if canImport(UIKit)
import UIKit

final class TableBlockView: UIView {
    private static let toolbarHeight: CGFloat = 36
    private static let minimumCellWidth: CGFloat = 132
    private static let minimumRowHeight: CGFloat = 42
    let preferredContentWidth: CGFloat

    init(table: TableBlock, context: RenderContext) {
        let rows = Self.normalizedRows(for: table)
        let columnCount = max(rows.map(\.count).max() ?? 0, 1)
        preferredContentWidth = CGFloat(columnCount) * Self.minimumCellWidth
        super.init(frame: .zero)
        
        backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.1, alpha: 1.0) : .white
        }
        layer.cornerRadius = 10
        layer.borderColor = UIColor.separator.withAlphaComponent(0.5).cgColor
        layer.borderWidth = 0.5
        clipsToBounds = true

        let toolbar = Self.toolbar(title: "表格", table: table, context: context)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbar)

        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

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

        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: Self.toolbarHeight),

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        isAccessibilityElement = true
        accessibilityLabel = "表格，\(table.header.count) 列，\(table.rows.count) 行"
    }

    required init?(coder: NSCoder) {
        preferredContentWidth = Self.minimumCellWidth
        super.init(coder: coder)
    }

    private static func row(cells: [InlineContent], isHeader: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 0

        for cell in cells {
            let cellView = Self.cellView(content: cell, isHeader: isHeader)
            cellView.widthAnchor.constraint(equalToConstant: minimumCellWidth).isActive = true
            row.addArrangedSubview(cellView)
        }

        return row
    }

    private static func normalizedRows(for table: TableBlock) -> [[InlineContent]] {
        (table.header.isEmpty ? [] : [table.header]) + table.rows
    }

    private static func cellView(content: InlineContent, isHeader: Bool) -> UIView {
        let cellView = UIView()
        cellView.backgroundColor = .clear
        cellView.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        cellView.layer.borderWidth = 0.5

        let label = UILabel()
        label.numberOfLines = 0
        let bodyFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .regular))
        let headerFont = UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .medium))
        label.font = isHeader ? headerFont : bodyFont
        label.textColor = .label
        label.text = MarkdownTextExtractor.plainText(from: content)
        label.translatesAutoresizingMaskIntoConstraints = false
        cellView.addSubview(label)

        NSLayoutConstraint.activate([
            cellView.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumRowHeight),
            label.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -12),
            label.topAnchor.constraint(greaterThanOrEqualTo: cellView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(lessThanOrEqualTo: cellView.bottomAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
        ])

        return cellView
    }

    private static func toolbar(title: String, table: TableBlock, context: RenderContext) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1.0) : UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1.0)
        }

        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.text = title
        label.translatesAutoresizingMaskIntoConstraints = false

        let actions = UIStackView()
        actions.axis = .horizontal
        actions.alignment = .center
        actions.spacing = 14
        actions.translatesAutoresizingMaskIntoConstraints = false
        
        let iconConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        
        let copyButton = UIButton(type: .custom)
        copyButton.setImage(UIImage(systemName: "doc.on.doc", withConfiguration: iconConfiguration), for: .normal)
        copyButton.tintColor = .secondaryLabel
        copyButton.imageView?.contentMode = .scaleAspectFit
        copyButton.addAction(UIAction { _ in
            let text = MarkdownTextExtractor.plainText(from: .table(table))
            UIPasteboard.general.string = text
            context.actions.onCopyTable?(text)
        }, for: .touchUpInside)
        
        let downloadButton = UIButton(type: .custom)
        downloadButton.setImage(UIImage(systemName: "arrow.down", withConfiguration: iconConfiguration), for: .normal)
        downloadButton.tintColor = .secondaryLabel
        downloadButton.imageView?.contentMode = .scaleAspectFit
        downloadButton.addAction(UIAction { _ in
            let text = MarkdownTextExtractor.plainText(from: .table(table))
            context.actions.onDownloadTable?(text)
        }, for: .touchUpInside)
        
        let expandButton = UIButton(type: .custom)
        expandButton.setImage(UIImage(systemName: "arrow.down.left.and.arrow.up.right", withConfiguration: iconConfiguration), for: .normal)
        expandButton.tintColor = .secondaryLabel
        expandButton.imageView?.contentMode = .scaleAspectFit
        expandButton.addAction(UIAction { _ in
            let text = MarkdownTextExtractor.plainText(from: .table(table))
            context.actions.onExpandTable?(text)
        }, for: .touchUpInside)

        let options = context.toolbarOptions
        if options.showsCopy {
            actions.addArrangedSubview(copyButton)
        }
        if options.showsDownload {
            actions.addArrangedSubview(downloadButton)
        }
        if options.showsExpand {
            actions.addArrangedSubview(expandButton)
        }

        container.addSubview(label)
        container.addSubview(actions)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            actions.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            actions.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }
}
#endif
