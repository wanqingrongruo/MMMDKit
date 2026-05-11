import MMMDCore

#if canImport(AppKit)
import AppKit

final class ParagraphBlockView: NSTextField {
    init(content: InlineContent, context: RenderContext) {
        super.init(frame: .zero)
        isEditable = false
        isSelectable = true
        isBordered = false
        drawsBackground = false
        lineBreakMode = .byWordWrapping
        maximumNumberOfLines = 0
        allowsEditingTextAttributes = true
        attributedStringValue = AppKitInlineRenderer.attributedString(from: content, baseFont: .preferredFont(forTextStyle: .body))
        setAccessibilityElement(true)
        setAccessibilityLabel(MarkdownTextExtractor.plainText(from: content))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
#endif
