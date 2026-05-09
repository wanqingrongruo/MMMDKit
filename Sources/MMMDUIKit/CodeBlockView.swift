import MMMDCore
import MMMDHighlighter

#if canImport(UIKit)
import UIKit

final class CodeBlockView: UIView {
    init(codeBlock: CodeBlock, context: RenderContext) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 10
        isAccessibilityElement = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        if let language = codeBlock.language, !language.isEmpty {
            stack.addArrangedSubview(Self.toolbar(language: language, codeBlock: codeBlock, context: context))
        } else {
            stack.addArrangedSubview(Self.toolbar(language: nil, codeBlock: codeBlock, context: context))
        }

        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = .monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 1, weight: .regular)
        textView.textColor = .label
        textView.text = codeBlock.content
        textView.isAccessibilityElement = true
        textView.accessibilityLabel = "代码块 \(codeBlock.language ?? "") \(codeBlock.content)"
        stack.addArrangedSubview(textView)
        applyHighlight(to: textView, codeBlock: codeBlock, context: context)

        addSubview(stack)
        let bottom = stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -context.theme.spacing.codePadding)
        bottom.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: context.theme.spacing.codePadding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -context.theme.spacing.codePadding),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: context.theme.spacing.codePadding),
            bottom
        ])
    }

    private func applyHighlight(to textView: UITextView, codeBlock: CodeBlock, context: RenderContext) {
        let highlighter = context.codeHighlighter ?? PlainCodeHighlighter()
        let theme = context.theme.codeTheme
        let baseFont = textView.font ?? .monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 1, weight: .regular)

        Task {
            guard let result = try? await highlighter.highlight(code: codeBlock.content, language: codeBlock.language, theme: theme) else {
                return
            }
            let attributed = UIKitHighlightRenderer.attributedString(from: result, theme: theme, baseFont: baseFont)
            await MainActor.run {
                textView.attributedText = attributed
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func toolbar(language: String?, codeBlock: CodeBlock, context: RenderContext) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center

        let languageLabel = UILabel()
        languageLabel.font = .preferredFont(forTextStyle: .caption1)
        languageLabel.textColor = .secondaryLabel
        languageLabel.text = language ?? "code"

        let copyButton = UIButton(type: .system)
        copyButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        copyButton.setTitle("复制", for: .normal)
        copyButton.addAction(UIAction { _ in
            UIPasteboard.general.string = CopyPayloadBuilder.payload(for: codeBlock).plainText
            context.actions.onCopyCode?(codeBlock.content, codeBlock.language)
        }, for: .touchUpInside)

        row.addArrangedSubview(languageLabel)
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(copyButton)
        return row
    }
}
#endif
