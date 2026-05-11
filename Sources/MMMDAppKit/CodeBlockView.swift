import MMMDCore
import MMMDHighlighter

#if canImport(AppKit)
import AppKit

final class CodeBlockView: NSView {
    init(codeBlock: CodeBlock, context: RenderContext) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 10
        setAccessibilityElement(false)

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(Self.toolbar(language: codeBlock.language, codeBlock: codeBlock, context: context))

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.font = .monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize - 1, weight: .regular)
        textView.textColor = .labelColor
        textView.string = codeBlock.content
        textView.setAccessibilityElement(true)
        textView.setAccessibilityLabel("代码块 \(codeBlock.language ?? "") \(codeBlock.content)")
        stack.addArrangedSubview(textView)
        applyHighlight(to: textView, codeBlock: codeBlock, context: context)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: context.theme.spacing.codePadding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -context.theme.spacing.codePadding),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: context.theme.spacing.codePadding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -context.theme.spacing.codePadding)
        ])
    }

    private func applyHighlight(to textView: NSTextView, codeBlock: CodeBlock, context: RenderContext) {
        let highlighter = context.codeHighlighter ?? PlainCodeHighlighter()
        let theme = context.theme.codeTheme
        let baseFont = textView.font ?? .monospacedSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize - 1, weight: .regular)

        Task {
            guard let result = try? await highlighter.highlight(code: codeBlock.content, language: codeBlock.language, theme: theme) else {
                return
            }
            let attributed = AppKitHighlightRenderer.attributedString(from: result, theme: theme, baseFont: baseFont)
            await MainActor.run {
                textView.textStorage?.setAttributedString(attributed)
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private static func toolbar(language: String?, codeBlock: CodeBlock, context: RenderContext) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        let languageLabel = NSTextField(labelWithString: language?.isEmpty == false ? language ?? "code" : "code")
        languageLabel.font = .preferredFont(forTextStyle: .caption1)
        languageLabel.textColor = .secondaryLabelColor

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let copyButton = CodeCopyButton(title: "复制", target: nil, action: nil)
        copyButton.bezelStyle = .inline
        copyButton.copyContext = CodeCopyContext(codeBlock: codeBlock, actions: context.actions)
        copyButton.target = CopyButtonTarget.shared
        copyButton.action = #selector(CopyButtonTarget.copyCode(_:))

        row.addArrangedSubview(languageLabel)
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(copyButton)
        return row
    }
}

private final class CodeCopyContext: NSObject {
    let codeBlock: CodeBlock
    let actions: MarkdownActions

    init(codeBlock: CodeBlock, actions: MarkdownActions) {
        self.codeBlock = codeBlock
        self.actions = actions
    }
}

private final class CodeCopyButton: NSButton {
    var copyContext: CodeCopyContext?
}

private final class CopyButtonTarget: NSObject {
    static let shared = CopyButtonTarget()

    @objc func copyCode(_ sender: NSButton) {
        guard let context = (sender as? CodeCopyButton)?.copyContext else {
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(CopyPayloadBuilder.payload(for: context.codeBlock).plainText, forType: .string)
        context.actions.onCopyCode?(context.codeBlock.content, context.codeBlock.language)
    }
}
#endif
