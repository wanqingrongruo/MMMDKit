import MMMDCore
import MMMDMath

#if canImport(SwiftMath)
import SwiftMath
#endif

#if canImport(AppKit)
import AppKit

final class MathBlockView: NSView {
    #if canImport(SwiftMath)
    private let mathLabel = MTMathUILabel()
    #endif
    private let fallbackLabel = NSTextField(labelWithString: "")

    init(mathBlock: MathBlock, context: RenderContext) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 10
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 0.5
        setAccessibilityElement(true)
        setAccessibilityLabel(mathBlock.latex)

        #if canImport(SwiftMath)
        mathLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mathLabel)
        #endif

        fallbackLabel.isEditable = false
        fallbackLabel.isBordered = false
        fallbackLabel.drawsBackground = false
        fallbackLabel.maximumNumberOfLines = 0
        fallbackLabel.lineBreakMode = .byWordWrapping
        fallbackLabel.alignment = mathBlock.displayMode ? .center : .natural
        fallbackLabel.font = .preferredFont(forTextStyle: .body)
        fallbackLabel.textColor = .labelColor
        fallbackLabel.stringValue = mathBlock.latex
        fallbackLabel.isHidden = true
        fallbackLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fallbackLabel)

        var constraints: [NSLayoutConstraint] = [
            fallbackLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            fallbackLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            fallbackLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            fallbackLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ]

        #if canImport(SwiftMath)
        constraints.append(contentsOf: [
            mathLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            mathLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            mathLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            mathLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
        #endif

        NSLayoutConstraint.activate(constraints)
        applyMath(mathBlock, context: context)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func applyMath(_ mathBlock: MathBlock, context: RenderContext) {
        guard let renderer = context.mathRenderer else {
            #if canImport(SwiftMath)
            configureNativeMath(mathBlock)
            #else
            showFallbackText(mathBlock.latex)
            #endif
            return
        }

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
                    self.showFallbackText(value)
                case .imageData:
                    self.showFallbackText(mathBlock.latex)
                }
                self.setAccessibilityLabel(result.accessibilityLabel)
            }
        }
    }

    #if canImport(SwiftMath)
    private func configureNativeMath(_ mathBlock: MathBlock) {
        mathLabel.latex = mathBlock.latex
        mathLabel.labelMode = mathBlock.displayMode ? .display : .text
        mathLabel.textAlignment = mathBlock.displayMode ? .center : .left
        mathLabel.fontSize = 18
        mathLabel.textColor = .labelColor
        mathLabel.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        mathLabel.displayErrorInline = false

        if mathLabel.error != nil {
            showFallbackText(mathBlock.latex)
        } else {
            mathLabel.isHidden = false
            fallbackLabel.isHidden = true
        }
    }
    #endif

    private func showFallbackText(_ text: String) {
        #if canImport(SwiftMath)
        mathLabel.isHidden = true
        #endif
        fallbackLabel.isHidden = false
        fallbackLabel.stringValue = text
    }
}
#endif
