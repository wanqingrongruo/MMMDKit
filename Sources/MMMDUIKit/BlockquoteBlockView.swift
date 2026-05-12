import MMMDCore

#if canImport(UIKit)
import UIKit

final class BlockquoteBlockView: UIView {
    init(blocks: [MarkdownBlock], context: RenderContext) {
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = true

        let indicator = UIView()
        indicator.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.3, alpha: 1.0) : UIColor(red: 0.88, green: 0.89, blue: 0.9, alpha: 1.0)
        }
        indicator.layer.cornerRadius = 2
        indicator.translatesAutoresizingMaskIntoConstraints = false

        let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .regular))
        
        let label = UILabel()
        label.numberOfLines = 0
        label.font = font
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.6, alpha: 1.0) : UIColor(red: 0.4, green: 0.4, blue: 0.42, alpha: 1.0)
        }
        label.text = blocks.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "\n")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = true
        label.accessibilityLabel = label.text
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(indicator)
        addSubview(label)
        NSLayoutConstraint.activate([
            indicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicator.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            indicator.widthAnchor.constraint(equalToConstant: 4),

            label.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
