import MMMDCore
import MMMDMath

#if canImport(SwiftMath)
import SwiftMath
#endif

#if canImport(UIKit)
import UIKit

public final class MathBlockView: UIView {
    #if canImport(SwiftMath)
    private let scrollView = UIScrollView()
    private let mathLabel = MTMathUILabel()
    #endif
    private let fallbackLabel = UILabel()

    public static func exactHeight(for mathBlock: MathBlock, width: CGFloat, context: RenderContext) -> CGFloat {
        if shouldUsePlainTextFallback(for: mathBlock.latex) {
            return fallbackHeight(for: fallbackText(for: mathBlock.latex), width: width)
        }

        #if canImport(SwiftMath)
        if context.mathRenderer == nil, Thread.isMainThread {
            let label = configuredMathLabel(for: mathBlock, context: context)
            let size = label.intrinsicContentSize
            if label.error == nil {
                return ceil(max(size.height, UIFont.preferredFont(forTextStyle: .body).lineHeight)) + 20
            }
        }
        #endif

        return fallbackHeight(for: mathBlock.latex, width: width)
    }

    private static func fallbackHeight(for text: String, width: CGFloat) -> CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: max(1, width - 24), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: paragraphStyle],
            context: nil
        )
        return ceil(rect.height) + 20
    }

    public init(mathBlock: MathBlock, context: RenderContext) {
        super.init(frame: .zero)
        mmmdSuppressTextViewAttachmentSelection()
        backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.1, alpha: 1.0) : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
        }
        layer.cornerRadius = 10
        layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        layer.borderWidth = 0.5
        isAccessibilityElement = true
        accessibilityLabel = mathBlock.latex

        #if canImport(SwiftMath)
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        mathLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(mathLabel)
        #endif

        fallbackLabel.numberOfLines = 0
        fallbackLabel.font = .preferredFont(forTextStyle: .body)
        fallbackLabel.textColor = .label
        fallbackLabel.textAlignment = mathBlock.displayMode ? .center : .natural
        fallbackLabel.text = mathBlock.latex
        fallbackLabel.isHidden = true
        fallbackLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            mathLabel.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            mathLabel.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            mathLabel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            mathLabel.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            mathLabel.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor),
            mathLabel.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        #endif

        NSLayoutConstraint.activate(constraints)
        applyMath(mathBlock, context: context)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func applyMath(_ mathBlock: MathBlock, context: RenderContext) {
        if Self.shouldUsePlainTextFallback(for: mathBlock.latex) {
            showFallbackText(Self.fallbackText(for: mathBlock.latex))
            return
        }

        guard let renderer = context.mathRenderer else {
            #if canImport(SwiftMath)
            configureNativeMath(mathBlock, context: context)
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
                self.accessibilityLabel = result.accessibilityLabel
            }
        }
    }

    #if canImport(SwiftMath)
    private func configureNativeMath(_ mathBlock: MathBlock, context: RenderContext) {
        let configured = Self.configuredMathLabel(for: mathBlock, context: context)
        mathLabel.latex = configured.latex
        mathLabel.labelMode = configured.labelMode
        mathLabel.textAlignment = configured.textAlignment
        mathLabel.fontSize = configured.fontSize
        mathLabel.textColor = configured.textColor
        mathLabel.contentInsets = configured.contentInsets
        mathLabel.displayErrorInline = false

        if mathLabel.error != nil {
            showFallbackText(mathBlock.latex)
        } else {
            scrollView.isHidden = false
            fallbackLabel.isHidden = true
        }
    }
    #endif

    private func showFallbackText(_ text: String) {
        #if canImport(SwiftMath)
        scrollView.isHidden = true
        #endif
        fallbackLabel.isHidden = false
        fallbackLabel.text = text
    }

    private static func shouldUsePlainTextFallback(for latex: String) -> Bool {
        latex.contains("\\text{") || latex.contains("\\mathrm{")
    }

    private static func fallbackText(for latex: String) -> String {
        var result = latex
        for command in ["text", "mathrm"] {
            result = replacingSingleArgumentCommand(command, in: result)
        }
        result = replacingTwoArgumentCommand("frac", in: result, template: "($1) / ($2)")
        result = replacingSingleArgumentCommand("sqrt", in: result, template: "√($1)")
        return result
    }

    private static func replacingSingleArgumentCommand(_ command: String, in text: String, template: String = "$1") -> String {
        let pattern = #"\\#(command)\{([^{}]*)\}"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return text
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }

    private static func replacingTwoArgumentCommand(_ command: String, in text: String, template: String) -> String {
        let pattern = #"\\#(command)\{([^{}]*)\}\{([^{}]*)\}"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return text
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }

    #if canImport(SwiftMath)
    private static func configuredMathLabel(for mathBlock: MathBlock, context: RenderContext) -> MTMathUILabel {
        let label = MTMathUILabel()
        label.latex = mathBlock.latex
        label.labelMode = mathBlock.displayMode ? .display : .text
        label.textAlignment = mathBlock.displayMode ? .center : .left
        label.fontSize = 18
        label.textColor = .label
        label.contentInsets = .zero
        label.displayErrorInline = false
        return label
    }
    #endif
}
#endif
