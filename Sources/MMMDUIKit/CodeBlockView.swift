import MMMDCore
import MMMDHighlighter

#if canImport(UIKit)
import UIKit

final class CodeBlockView: UIView {
    init(codeBlock: CodeBlock, context: RenderContext) {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        layer.cornerRadius = 10
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 0.5
        clipsToBounds = true
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
        textView.layoutMargins = UIEdgeInsets(top: 0, left: context.theme.spacing.codePadding, bottom: 0, right: context.theme.spacing.codePadding)
        textView.textContainerInset = UIEdgeInsets(
            top: 0,
            left: context.theme.spacing.codePadding,
            bottom: 0,
            right: context.theme.spacing.codePadding
        )
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(textView)
        applyHighlight(to: textView, codeBlock: codeBlock, context: context)

        addSubview(stack)
        let bottom = stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -context.theme.spacing.codePadding)
        bottom.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
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
        row.spacing = 14
        row.backgroundColor = .secondarySystemBackground
        row.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        row.isLayoutMarginsRelativeArrangement = true
        row.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let languageLabel = UILabel()
        languageLabel.font = .preferredFont(forTextStyle: .caption1)
        languageLabel.textColor = .secondaryLabel
        languageLabel.text = language ?? "code"
        languageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let copyButton = UIButton(type: .custom)
        copyButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        let iconConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        copyButton.setImage(UIImage(systemName: "doc.on.doc", withConfiguration: iconConfiguration), for: .normal)
        copyButton.tintColor = .secondaryLabel
        copyButton.imageView?.contentMode = .scaleAspectFit
        copyButton.addAction(UIAction { _ in
            UIPasteboard.general.string = CopyPayloadBuilder.payload(for: codeBlock).plainText
            context.actions.onCopyCode?(codeBlock.content, codeBlock.language)
        }, for: .touchUpInside)

        let downloadIcon = UIImageView(image: UIImage(systemName: "arrow.down"))
        downloadIcon.tintColor = .secondaryLabel
        downloadIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true

        let expandIcon = UIImageView(image: UIImage(systemName: "arrow.up.left.and.arrow.down.right"))
        expandIcon.tintColor = .secondaryLabel
        expandIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true

        row.addArrangedSubview(languageLabel)
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(copyButton)
        row.addArrangedSubview(downloadIcon)
        row.addArrangedSubview(expandIcon)
        return row
    }
}
#endif
