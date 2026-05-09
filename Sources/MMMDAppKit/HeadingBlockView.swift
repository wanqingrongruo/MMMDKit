import MMMDCore

#if canImport(AppKit)
import AppKit

final class HeadingBlockView: NSTextField {
    init(level: Int, content: InlineContent, context: RenderContext) {
        super.init(frame: .zero)
        isEditable = false
        isBordered = false
        drawsBackground = false
        lineBreakMode = .byWordWrapping
        maximumNumberOfLines = 0
        font = Self.font(for: level)
        textColor = .labelColor
        stringValue = MarkdownTextExtractor.plainText(from: content)
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        setAccessibilityLabel(stringValue)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func font(for level: Int) -> NSFont {
        switch level {
        case 1:
            return .preferredFont(forTextStyle: .title2)
        case 2:
            return .preferredFont(forTextStyle: .title3)
        default:
            return .preferredFont(forTextStyle: .headline)
        }
    }
}
#endif
