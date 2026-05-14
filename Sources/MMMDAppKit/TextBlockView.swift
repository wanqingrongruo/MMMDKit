import MMMDCore

#if canImport(AppKit)
import AppKit

final class TextBlockView: NSTextView {
    private var onLinkTap: (@Sendable (URL) -> Void)?

    init(blocks: [MarkdownBlock], context: RenderContext, textColor: NSColor? = nil) {
        super.init(frame: .zero, textContainer: NSTextContainer())
        backgroundColor = .clear
        isEditable = false
        isSelectable = true
        drawsBackground = false
        textContainerInset = .zero
        textContainer?.lineFragmentPadding = 0
        onLinkTap = context.actions.onLinkTap
        
        let resolvedTextColor = textColor ?? .labelColor
        let result = NSMutableAttributedString()
        for (index, block) in blocks.enumerated() {
            let attributed: NSAttributedString
            switch block {
            case .heading(let level, let content):
                let font = Self.headingFont(for: level)
                attributed = AppKitInlineRenderer.attributedString(from: content, baseFont: font, textColor: resolvedTextColor)
            case .paragraph(let content):
                let font = NSFont.preferredFont(forTextStyle: .body)
                attributed = AppKitInlineRenderer.attributedString(from: content, baseFont: font, textColor: resolvedTextColor)
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
        textStorage?.setAttributedString(result)
        setAccessibilityElement(true)
        setAccessibilityLabel(result.string)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func clicked(onLink link: Any, at charIndex: Int) {
        if let url = link as? URL {
            onLinkTap?(url)
        } else if let urlString = link as? String, let url = URL(string: urlString) {
            onLinkTap?(url)
        }
    }

    private static func headingFont(for level: Int) -> NSFont {
        switch level {
        case 1:
            return NSFont.systemFont(ofSize: 24, weight: .bold)
        case 2:
            return NSFont.systemFont(ofSize: 20, weight: .bold)
        default:
            return NSFont.systemFont(ofSize: 18, weight: .semibold)
        }
    }
}
#endif
