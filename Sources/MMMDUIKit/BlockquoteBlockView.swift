import MMMDCore

#if canImport(UIKit)
import UIKit

final class BlockquoteBlockView: UIView {
    init(blocks: [MarkdownBlock], context: RenderContext) {
        super.init(frame: .zero)
        backgroundColor = .tertiarySystemBackground
        layer.cornerRadius = 10
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 0.5
        clipsToBounds = true

        let indicator = UIView()
        indicator.backgroundColor = .secondaryLabel
        indicator.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.text = blocks.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "\n")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = true
        label.accessibilityLabel = label.text
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(indicator)
        addSubview(label)
        NSLayoutConstraint.activate([
            indicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            indicator.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            indicator.widthAnchor.constraint(equalToConstant: 3),

            label.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
