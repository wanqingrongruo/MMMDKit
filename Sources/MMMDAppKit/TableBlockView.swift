import MMMDCore

#if canImport(AppKit)
import AppKit

final class TableBlockView: NSView {
    private static let toolbarHeight: CGFloat = 36
    private static let minimumCellWidth: CGFloat = 120
    private static let minimumRowHeight: CGFloat = 34
    private static let cellTextInset: CGFloat = 8
    private static let horizontalScrollerHeight: CGFloat = 14
    let preferredContentWidth: CGFloat

    init(table: TableBlock, context: RenderContext) {
        let rows = Self.normalizedRows(for: table)
        let columnCount = max(rows.map(\.cells.count).max() ?? 0, 1)
        preferredContentWidth = CGFloat(columnCount) * Self.minimumCellWidth
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        layer?.cornerRadius = 10
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 0.5

        let toolbar = Self.toolbar(title: "表格")
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbar)

        let scrollView = NSScrollView()
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        let rowHeights = rows.map { Self.rowHeight(cells: $0.cells, isHeader: $0.isHeader) }
        let tableWidth = CGFloat(columnCount) * Self.minimumCellWidth
        let tableHeight = rowHeights.reduce(0, +)
        let contentView = FlippedTableDocumentView(frame: NSRect(x: 0, y: 0, width: tableWidth, height: tableHeight))

        var y: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let rowHeight = rowHeights[index]
            for column in 0..<columnCount {
                let cell = column < row.cells.count ? row.cells[column] : InlineContent(text: "")
                let cellView = Self.cellView(content: cell, isHeader: row.isHeader)
                cellView.frame = NSRect(
                    x: CGFloat(column) * Self.minimumCellWidth,
                    y: y,
                    width: Self.minimumCellWidth,
                    height: rowHeight
                )
                contentView.addSubview(cellView)
            }
            y += rowHeight
        }

        scrollView.documentView = contentView
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: Self.toolbarHeight),

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        setAccessibilityElement(true)
        setAccessibilityLabel("表格，\(table.header.count) 列，\(table.rows.count) 行")
    }

    required init?(coder: NSCoder) {
        preferredContentWidth = Self.minimumCellWidth
        super.init(coder: coder)
    }

    static func height(for table: TableBlock) -> CGFloat {
        let rows = normalizedRows(for: table)
        let contentHeight = rows.map { rowHeight(cells: $0.cells, isHeader: $0.isHeader) }.reduce(0, +)
        return toolbarHeight + max(minimumRowHeight, contentHeight) + horizontalScrollerHeight
    }

    private static func normalizedRows(for table: TableBlock) -> [(cells: [InlineContent], isHeader: Bool)] {
        var rows: [(cells: [InlineContent], isHeader: Bool)] = []
        if !table.header.isEmpty {
            rows.append((table.header, true))
        }
        rows.append(contentsOf: table.rows.map { ($0, false) })
        return rows.isEmpty ? [([InlineContent(text: "")], false)] : rows
    }

    private static func rowHeight(cells: [InlineContent], isHeader: Bool) -> CGFloat {
        let font: NSFont = isHeader ? .preferredFont(forTextStyle: .headline) : .preferredFont(forTextStyle: .body)
        let textWidth = max(1, minimumCellWidth - cellTextInset * 2)
        let contentHeight = cells.map { cell -> CGFloat in
            let text = MarkdownTextExtractor.plainText(from: cell)
            let rect = (text as NSString).boundingRect(
                with: NSSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font]
            )
            return ceil(rect.height)
        }.max() ?? 0
        return max(minimumRowHeight, contentHeight + cellTextInset * 2)
    }

    private static func cellView(content: InlineContent, isHeader: Bool) -> NSView {
        let cellView = NSView(frame: .zero)
        cellView.wantsLayer = true
        cellView.layer?.backgroundColor = (isHeader ? NSColor.controlBackgroundColor : NSColor.textBackgroundColor).cgColor
        cellView.layer?.borderColor = NSColor.separatorColor.cgColor
        cellView.layer?.borderWidth = 0.5

        let label = NSTextField(wrappingLabelWithString: MarkdownTextExtractor.plainText(from: content))
        label.font = isHeader ? .preferredFont(forTextStyle: .headline) : .preferredFont(forTextStyle: .body)
        label.textColor = .labelColor
        label.drawsBackground = false
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        cellView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: cellTextInset),
            label.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -cellTextInset),
            label.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: cellView.topAnchor, constant: cellTextInset / 2),
            label.bottomAnchor.constraint(lessThanOrEqualTo: cellView.bottomAnchor, constant: -cellTextInset / 2)
        ])

        return cellView
    }

    private static func toolbar(title: String) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        let label = NSTextField(labelWithString: title)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        let actions = NSStackView()
        actions.orientation = .horizontal
        actions.alignment = .centerY
        actions.spacing = 14
        actions.translatesAutoresizingMaskIntoConstraints = false
        for symbol in ["doc.on.doc", "arrow.down", "arrow.up.left.and.arrow.down.right"] {
            let imageView = NSImageView()
            imageView.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            imageView.contentTintColor = .secondaryLabelColor
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
            actions.addArrangedSubview(imageView)
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

private final class FlippedTableDocumentView: NSView {
    override var isFlipped: Bool {
        true
    }
}
#endif
