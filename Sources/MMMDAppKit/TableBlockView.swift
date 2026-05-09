import MMMDCore

#if canImport(AppKit)
import AppKit

final class TableBlockView: NSScrollView {
    init(table: TableBlock, context: RenderContext) {
        super.init(frame: .zero)
        hasHorizontalScroller = true
        hasVerticalScroller = false
        drawsBackground = false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0

        if !table.header.isEmpty {
            stack.addArrangedSubview(Self.row(cells: table.header, isHeader: true))
        }
        for row in table.rows {
            stack.addArrangedSubview(Self.row(cells: row, isHeader: false))
        }

        documentView = stack
        setAccessibilityElement(true)
        setAccessibilityLabel("表格，\(table.header.count) 列，\(table.rows.count) 行")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func row(cells: [InlineContent], isHeader: Bool) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 0

        for cell in cells {
            let label = NSTextField(wrappingLabelWithString: MarkdownTextExtractor.plainText(from: cell))
            label.font = isHeader ? .preferredFont(forTextStyle: .headline) : .preferredFont(forTextStyle: .body)
            label.textColor = .labelColor
            label.wantsLayer = true
            label.layer?.borderColor = NSColor.separatorColor.cgColor
            label.layer?.borderWidth = 0.5
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
            row.addArrangedSubview(label)
        }

        return row
    }
}
#endif
