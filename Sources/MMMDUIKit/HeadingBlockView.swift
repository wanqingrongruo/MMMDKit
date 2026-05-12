import MMMDCore

#if canImport(UIKit)
import UIKit

final class HeadingBlockView: UILabel {
    init(level: Int, content: InlineContent, context: RenderContext) {
        super.init(frame: .zero)
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        adjustsFontForContentSizeCategory = true
        font = Self.font(for: level)
        textColor = .label
        text = MarkdownTextExtractor.plainText(from: content)
        isAccessibilityElement = true
        accessibilityTraits.insert(.header)
        accessibilityLabel = text
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func font(for level: Int) -> UIFont {
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
