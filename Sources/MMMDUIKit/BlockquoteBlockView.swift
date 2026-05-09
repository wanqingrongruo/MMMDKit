import MMMDCore

#if canImport(UIKit)
import UIKit

final class BlockquoteBlockView: UIView {
    init(blocks: [MarkdownBlock], context: RenderContext) {
        super.init(frame: .zero)

        let indicator = UIView()
        indicator.backgroundColor = .separator
        indicator.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.text = blocks.map(MarkdownTextExtractor.plainText(from:)).joined(separator: "\n")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = true
        label.accessibilityLabel = label.text

        addSubview(indicator)
        addSubview(label)
        NSLayoutConstraint.activate([
            indicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicator.topAnchor.constraint(equalTo: topAnchor),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 3),

            label.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 10),
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
