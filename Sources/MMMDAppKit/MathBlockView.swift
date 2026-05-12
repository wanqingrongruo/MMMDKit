import MMMDCore
import MMMDMath

#if canImport(AppKit)
import AppKit

final class MathBlockView: NSView {
    private let label = NSTextField(labelWithString: "")

    init(mathBlock: MathBlock, context: RenderContext) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 10
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 0.5
        setAccessibilityElement(true)
        setAccessibilityLabel(mathBlock.latex)

        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.alignment = mathBlock.displayMode ? .center : .natural
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .labelColor
        label.stringValue = mathBlock.latex
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
                    self.label.stringValue = value
                case .imageData:
                    self.label.stringValue = mathBlock.latex
                }
                self.setAccessibilityLabel(result.accessibilityLabel)
            }
        }
    }
}
#endif
