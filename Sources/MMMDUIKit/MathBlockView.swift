import MMMDCore
import MMMDMath

#if canImport(UIKit)
import UIKit

final class MathBlockView: UIView {
    private let label = UILabel()

    init(mathBlock: MathBlock, context: RenderContext) {
        super.init(frame: .zero)
        backgroundColor = .tertiarySystemBackground
        layer.cornerRadius = 10
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 0.5
        isAccessibilityElement = true
        accessibilityLabel = mathBlock.latex

        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.textAlignment = mathBlock.displayMode ? .center : .natural
        label.text = mathBlock.latex
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
        applyMath(mathBlock, context: context)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func applyMath(_ mathBlock: MathBlock, context: RenderContext) {
        let renderer = context.mathRenderer ?? FallbackMathRenderer()
        Task {
            guard let result = try? await renderer.render(
                latex: mathBlock.latex,
                displayMode: mathBlock.displayMode,
                environment: .init(colorScheme: context.environment.colorScheme)
            ) else {
                return
            }

            await MainActor.run {
                switch result.representation {
                case .plainText(let value), .svg(let value):
                    self.label.text = value
                case .imageData:
                    self.label.text = mathBlock.latex
                }
                self.accessibilityLabel = result.accessibilityLabel
            }
        }
    }
}
#endif
