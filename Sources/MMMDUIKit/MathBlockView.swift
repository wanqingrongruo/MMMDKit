import MMMDCore
import MMMDMath

#if canImport(UIKit)
import UIKit

final class MathBlockView: UILabel {
    init(mathBlock: MathBlock, context: RenderContext) {
        super.init(frame: .zero)
        numberOfLines = 0
        font = .preferredFont(forTextStyle: .body)
        textColor = .label
        textAlignment = mathBlock.displayMode ? .center : .natural
        text = mathBlock.latex
        isAccessibilityElement = true
        accessibilityLabel = mathBlock.latex
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
                    text = value
                case .imageData:
                    text = mathBlock.latex
                }
                accessibilityLabel = result.accessibilityLabel
            }
        }
    }
}
#endif
