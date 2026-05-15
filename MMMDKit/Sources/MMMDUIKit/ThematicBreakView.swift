import MMMDCore

#if canImport(UIKit)
import UIKit

public final class ThematicBreakView: UIView {
    public static func exactHeight(context: RenderContext) -> CGFloat {
        1
    }

    public init(context: RenderContext) {
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityLabel = "分割线"

        let line = UIView()
        line.backgroundColor = UIColor.separator.withAlphaComponent(0.18)
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)

        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.centerYAnchor.constraint(equalTo: centerYAnchor),
            line.heightAnchor.constraint(equalToConstant: 1),
            heightAnchor.constraint(equalToConstant: Self.exactHeight(context: context))
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
