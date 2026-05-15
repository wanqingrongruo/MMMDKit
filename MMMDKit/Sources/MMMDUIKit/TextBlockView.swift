import MMMDCore

#if canImport(UIKit)
import UIKit

public final class TextBlockView: UITextView, UITextViewDelegate {
    private var onLinkTap: (@Sendable (URL) -> Void)?

    private static let attrStringCache = NSCache<NSString, NSAttributedString>()

    public init(blocks: [MarkdownBlock], context: RenderContext, cacheKey: String? = nil, textColor: UIColor? = nil) {
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
        let result: NSAttributedString
        
        if let cacheKey = cacheKey as NSString?,
           let cached = Self.attrStringCache.object(forKey: cacheKey) {
            result = cached
        } else {
            result = Self.attributedString(for: blocks, context: context, textColor: resolvedTextColor, listLevel: 0, blockquoteLevel: 0)
            if let cacheKey = cacheKey as NSString? {
                Self.attrStringCache.setObject(result, forKey: cacheKey)
            }
        }
        
        attributedText = result
        isAccessibilityElement = true
        accessibilityLabel = result.string
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        onLinkTap?(URL)
        return false
    }
    
    public static func attributedString(for blocks: [MarkdownBlock], context: RenderContext, cacheKey: String? = nil, textColor: UIColor = .label, listLevel: Int = 0, blockquoteLevel: Int = 0) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let blockSpacing = context.theme.spacing.blockSpacing
        
        for (index, block) in blocks.enumerated() {
            let blockResult = NSMutableAttributedString()
            let currentIndent = CGFloat(listLevel * 24 + blockquoteLevel * 16)
            
            switch block {
            case .heading(let level, let content):
                let font = headingFont(for: level)
                blockResult.append(UIKitInlineRenderer.attributedString(from: content, baseFont: font, textColor: textColor))
                applyParagraphStyle(to: blockResult, indent: currentIndent, firstLineIndent: currentIndent)
                
            case .paragraph(let content):
                let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .regular))
                let color = blockquoteLevel > 0 ? UIColor.secondaryLabel : textColor
                blockResult.append(UIKitInlineRenderer.attributedString(from: content, baseFont: font, textColor: color))
                applyParagraphStyle(to: blockResult, indent: currentIndent, firstLineIndent: currentIndent)
                
            case .blockquote(let bBlocks):
                blockResult.append(attributedString(for: bBlocks, context: context, textColor: textColor, listLevel: listLevel, blockquoteLevel: blockquoteLevel + 1))
                
            case .list(let list):
                for (i, item) in list.items.enumerated() {
                    let marker: String
                    switch list.style {
                    case .ordered(let start): marker = "\(start + i)."
                    case .unordered: marker = "•"
                    case .task: marker = "□"
                    }
                    
                    let itemResult = NSMutableAttributedString()
                    let markerFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .regular))
                    let markerString = NSAttributedString(string: "\(marker)\t", attributes: [
                        .font: markerFont,
                        .foregroundColor: UIColor.secondaryLabel
                    ])
                    itemResult.append(markerString)
                    
                    let contentAttr = attributedString(for: item.blocks, context: context, textColor: textColor, listLevel: listLevel + 1, blockquoteLevel: blockquoteLevel)
                    itemResult.append(contentAttr)
                    
                    var firstParagraphRange: NSRange?
                    let string = itemResult.string as NSString
                    string.enumerateSubstrings(in: NSRange(location: 0, length: string.length), options: .byParagraphs) { _, range, _, stop in
                        firstParagraphRange = range
                        stop.pointee = true
                    }
                    
                    if let range = firstParagraphRange {
                        itemResult.enumerateAttribute(.paragraphStyle, in: range, options: []) { value, r, _ in
                            let style = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
                            style.firstLineHeadIndent = currentIndent
                            style.headIndent = currentIndent + 24
                            let tabStop = NSTextTab(textAlignment: .left, location: currentIndent + 24, options: [:])
                            style.tabStops = [tabStop]
                            style.defaultTabInterval = 24
                            itemResult.addAttribute(.paragraphStyle, value: style, range: r)
                        }
                    }
                    
                    blockResult.append(itemResult)
                    if i < list.items.count - 1 {
                        let newline = NSAttributedString(string: "\n", attributes: [.font: UIFont.systemFont(ofSize: 1)])
                        blockResult.append(newline)
                    }
                }
            default:
                continue
            }
            
            if blockResult.length > 0 {
                if index < blocks.count - 1 {
                    addParagraphSpacing(to: blockResult, spacing: blockSpacing)
                    let newline = NSAttributedString(string: "\n", attributes: [.font: UIFont.systemFont(ofSize: 1)])
                    blockResult.append(newline)
                }
                result.append(blockResult)
            }
        }
        
        return result
    }

    private static func applyParagraphStyle(to attrString: NSMutableAttributedString, indent: CGFloat, firstLineIndent: CGFloat) {
        attrString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: attrString.length), options: []) { value, range, _ in
            let style = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            style.headIndent = indent
            style.firstLineHeadIndent = firstLineIndent
            
            if indent > 0 {
                let tabStop = NSTextTab(textAlignment: .left, location: indent, options: [:])
                style.tabStops = [tabStop]
                style.defaultTabInterval = indent
            }
            
            attrString.addAttribute(.paragraphStyle, value: style, range: range)
        }
    }

    private static func addParagraphSpacing(to attrString: NSMutableAttributedString, spacing: CGFloat) {
        var lastParagraphRange: NSRange?
        let string = attrString.string as NSString
        string.enumerateSubstrings(in: NSRange(location: 0, length: string.length), options: .byParagraphs) { _, range, _, _ in
            lastParagraphRange = range
        }
        
        if let range = lastParagraphRange {
            attrString.enumerateAttribute(.paragraphStyle, in: range, options: []) { value, r, _ in
                let style = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
                style.paragraphSpacing = spacing
                attrString.addAttribute(.paragraphStyle, value: style, range: r)
            }
        }
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
