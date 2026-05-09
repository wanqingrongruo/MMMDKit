import MMMDCore

#if canImport(AppKit)
import AppKit

final class ParagraphBlockView: NSTextView, NSTextViewDelegate {
    private var onLinkTap: (@Sendable (URL) -> Void)?

    init(content: InlineContent, context: RenderContext) {
        super.init(frame: .zero)
        isEditable = false
        isSelectable = true
        drawsBackground = false
        textContainerInset = .zero
        textContainer?.lineFragmentPadding = 0
        delegate = self
        onLinkTap = context.actions.onLinkTap
        textStorage?.setAttributedString(AppKitInlineRenderer.attributedString(from: content, baseFont: .preferredFont(forTextStyle: .body)))
        setAccessibilityElement(true)
        setAccessibilityLabel(MarkdownTextExtractor.plainText(from: content))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        guard let url = link as? URL else {
            return false
        }
        onLinkTap?(url)
        return true
    }
}
#endif
