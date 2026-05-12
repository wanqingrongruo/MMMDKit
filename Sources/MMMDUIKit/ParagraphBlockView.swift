import MMMDCore

#if canImport(UIKit)
import UIKit

final class ParagraphBlockView: UITextView, UITextViewDelegate {
    private var onLinkTap: (@Sendable (URL) -> Void)?

    init(content: InlineContent, context: RenderContext) {
        super.init(frame: .zero, textContainer: nil)
        backgroundColor = .clear
        isEditable = false
        isScrollEnabled = false
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        adjustsFontForContentSizeCategory = true
        delegate = self
        onLinkTap = context.actions.onLinkTap
        attributedText = UIKitInlineRenderer.attributedString(from: content, baseFont: .preferredFont(forTextStyle: .body))
        isAccessibilityElement = true
        accessibilityLabel = MarkdownTextExtractor.plainText(from: content)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        onLinkTap?(URL)
        return false
    }
}
#endif
