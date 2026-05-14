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

        let textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.6, alpha: 1.0) : UIColor(red: 0.4, green: 0.4, blue: 0.42, alpha: 1.0)
        }
        let textBlockView = TextBlockView(blocks: blocks, context: context, textColor: textColor)
        textBlockView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(indicator)
        addSubview(textBlockView)
        NSLayoutConstraint.activate([
            indicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicator.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            indicator.widthAnchor.constraint(equalToConstant: 4),

            textBlockView.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 12),
            textBlockView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textBlockView.topAnchor.constraint(equalTo: topAnchor),
            textBlockView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
