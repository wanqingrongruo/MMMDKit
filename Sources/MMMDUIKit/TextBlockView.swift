import MMMDCore

#if canImport(UIKit)
import UIKit

final class TextBlockView: UITextView, UITextViewDelegate {
    private var onLinkTap: (@Sendable (URL) -> Void)?

    init(blocks: [MarkdownBlock], context: RenderContext, textColor: UIColor? = nil) {
        super.init(frame: .zero, textContainer: nil)
        backgroundColor = .clear
        isEditable = false
        isScrollEnabled = false
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        adjustsFontForContentSizeCategory = true
        delegate = self
        onLinkTap = context.actions.onLinkTap
        
        let resolvedTextColor = textColor ?? .label
        let result = NSMutableAttributedString()
        for (index, block) in blocks.enumerated() {
            let attributed: NSAttributedString
            switch block {
            case .heading(let level, let content):
                let font = Self.headingFont(for: level)
                attributed = UIKitInlineRenderer.attributedString(from: content, baseFont: font, textColor: resolvedTextColor)
            case .paragraph(let content):
                let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .regular))
                attributed = UIKitInlineRenderer.attributedString(from: content, baseFont: font, textColor: resolvedTextColor)
            default:
                continue
            }
            
            let mutableAttributed = NSMutableAttributedString(attributedString: attributed)
            if index < blocks.count - 1 {
                let paragraphStyle = NSMutableParagraphStyle()
                if mutableAttributed.length > 0, let existingStyle = mutableAttributed.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
                    paragraphStyle.setParagraphStyle(existingStyle)
                }
                paragraphStyle.paragraphSpacing = context.theme.spacing.blockSpacing
                if mutableAttributed.length > 0 {
                    mutableAttributed.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mutableAttributed.length))
                }
                mutableAttributed.append(NSAttributedString(string: "\n", attributes: [.paragraphStyle: paragraphStyle]))
            }
            result.append(mutableAttributed)
        }
        attributedText = result
        isAccessibilityElement = true
        accessibilityLabel = result.string
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        onLinkTap?(URL)
        return false
    }

    private static func headingFont(for level: Int) -> UIFont {
        switch level {
        case 1:
            return UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 20, weight: .medium))
        case 2:
            return UIFontMetrics(forTextStyle: .title3).scaledFont(for: UIFont.systemFont(ofSize: 18, weight: .medium))
        default:
            return UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .medium))
        }
    }
}
#endif
