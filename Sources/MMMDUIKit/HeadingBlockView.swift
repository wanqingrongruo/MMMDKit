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
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func font(for level: Int) -> UIFont {
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
