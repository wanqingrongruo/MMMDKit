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
        let result = Self.attributedString(for: blocks, context: context, textColor: resolvedTextColor, listLevel: 0, blockquoteLevel: 0)
        
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
    
    private static func attributedString(for blocks: [MarkdownBlock], context: RenderContext, textColor: NSColor, listLevel: Int, blockquoteLevel: Int) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let blockSpacing = context.theme.spacing.blockSpacing
        
        for (index, block) in blocks.enumerated() {
            let blockResult = NSMutableAttributedString()
            let currentIndent = CGFloat(listLevel * 24 + blockquoteLevel * 16)
            
            switch block {
            case .heading(let level, let content):
                let font = headingFont(for: level)
                blockResult.append(AppKitInlineRenderer.attributedString(from: content, baseFont: font, textColor: textColor))
                applyParagraphStyle(to: blockResult, indent: currentIndent, firstLineIndent: currentIndent)
                
            case .paragraph(let content):
                let font = NSFont.preferredFont(forTextStyle: .body)
                let color = blockquoteLevel > 0 ? NSColor.secondaryLabelColor : textColor
                blockResult.append(AppKitInlineRenderer.attributedString(from: content, baseFont: font, textColor: color))
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
                    let markerFont = NSFont.preferredFont(forTextStyle: .body)
                    let markerString = NSAttributedString(string: "\(marker)\t", attributes: [
                        .font: markerFont,
                        .foregroundColor: NSColor.secondaryLabelColor
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
                        let newline = NSAttributedString(string: "\n", attributes: [.font: NSFont.systemFont(ofSize: 1)])
                        blockResult.append(newline)
                    }
                }
            default:
                continue
            }
            
            if blockResult.length > 0 {
                if index < blocks.count - 1 {
                    addParagraphSpacing(to: blockResult, spacing: blockSpacing)
                    let newline = NSAttributedString(string: "\n", attributes: [.font: NSFont.systemFont(ofSize: 1)])
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
