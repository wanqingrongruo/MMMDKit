import MMMDCore
import MMMDMath

#if canImport(AppKit)
import AppKit

final class MathBlockView: NSTextField {
    init(mathBlock: MathBlock, context: RenderContext) {
        super.init(frame: .zero)
        isEditable = false
        isBordered = false
        drawsBackground = false
        maximumNumberOfLines = 0
        alignment = mathBlock.displayMode ? .center : .natural
        font = .preferredFont(forTextStyle: .body)
        textColor = .labelColor
        stringValue = mathBlock.latex
        setAccessibilityElement(true)
        setAccessibilityLabel(mathBlock.latex)
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
                    stringValue = value
                case .imageData:
                    stringValue = mathBlock.latex
                }
                setAccessibilityLabel(result.accessibilityLabel)
            }
        }
    }
}
#endif
