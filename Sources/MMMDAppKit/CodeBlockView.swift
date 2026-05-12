import MMMDCore
import MMMDHighlighter

#if canImport(AppKit)
import AppKit

final class CodeBlockView: NSView {
    init(codeBlock: CodeBlock, context: RenderContext) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        layer?.cornerRadius = 10
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 0.5
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
        textView.textContainerInset = NSSize(width: context.theme.spacing.codePadding, height: 0)
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
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
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
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false

        let languageLabel = NSTextField(labelWithString: language?.isEmpty == false ? language ?? "code" : "code")
        languageLabel.font = .preferredFont(forTextStyle: .caption1)
        languageLabel.textColor = .secondaryLabelColor

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let copyButton = CodeActionButton(title: "", target: nil, action: nil)
        copyButton.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "复制")
        copyButton.contentTintColor = .secondaryLabelColor
        copyButton.isBordered = false
        copyButton.imagePosition = .imageOnly
        copyButton.imageScaling = .scaleProportionallyDown
        copyButton.actionContext = CodeActionContext(codeBlock: codeBlock, actions: context.actions)
        copyButton.target = ActionButtonTarget.shared
        copyButton.action = #selector(ActionButtonTarget.copyCode(_:))

        let downloadButton = CodeActionButton(title: "", target: nil, action: nil)
        downloadButton.image = NSImage(systemSymbolName: "arrow.down", accessibilityDescription: "下载")
        downloadButton.contentTintColor = .secondaryLabelColor
        downloadButton.isBordered = false
        downloadButton.imagePosition = .imageOnly
        downloadButton.imageScaling = .scaleProportionallyDown
        downloadButton.actionContext = CodeActionContext(codeBlock: codeBlock, actions: context.actions)
        downloadButton.target = ActionButtonTarget.shared
        downloadButton.action = #selector(ActionButtonTarget.downloadCode(_:))
        downloadButton.widthAnchor.constraint(equalToConstant: 16).isActive = true

        let expandButton = CodeActionButton(title: "", target: nil, action: nil)
        expandButton.image = NSImage(systemSymbolName: "arrow.down.left.and.arrow.up.right", accessibilityDescription: "全屏")
        expandButton.contentTintColor = .secondaryLabelColor
        expandButton.isBordered = false
        expandButton.imagePosition = .imageOnly
        expandButton.imageScaling = .scaleProportionallyDown
        expandButton.actionContext = CodeActionContext(codeBlock: codeBlock, actions: context.actions)
        expandButton.target = ActionButtonTarget.shared
        expandButton.action = #selector(ActionButtonTarget.expandCode(_:))
        expandButton.widthAnchor.constraint(equalToConstant: 16).isActive = true

        row.addArrangedSubview(languageLabel)
        row.addArrangedSubview(spacer)
        
        let options = context.toolbarOptions
        if options.showsCopy {
            row.addArrangedSubview(copyButton)
        }
        if options.showsDownload {
            row.addArrangedSubview(downloadButton)
        }
        if options.showsExpand {
            row.addArrangedSubview(expandButton)
        }

        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }
}

private final class CodeActionContext: NSObject {
    let codeBlock: CodeBlock
    let actions: MarkdownActions

    init(codeBlock: CodeBlock, actions: MarkdownActions) {
        self.codeBlock = codeBlock
        self.actions = actions
    }
}

private final class CodeActionButton: NSButton {
    var actionContext: CodeActionContext?
}

private final class ActionButtonTarget: NSObject {
    static let shared = ActionButtonTarget()

    @objc func copyCode(_ sender: NSButton) {
        guard let context = (sender as? CodeActionButton)?.actionContext else {
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(CopyPayloadBuilder.payload(for: context.codeBlock).plainText, forType: .string)
        context.actions.onCopyCode?(context.codeBlock.content, context.codeBlock.language)
    }

    @objc func downloadCode(_ sender: NSButton) {
        guard let context = (sender as? CodeActionButton)?.actionContext else {
            return
        }
        context.actions.onDownloadCode?(context.codeBlock.content, context.codeBlock.language)
    }

    @objc func expandCode(_ sender: NSButton) {
        guard let context = (sender as? CodeActionButton)?.actionContext else {
            return
        }
        context.actions.onExpandCode?(context.codeBlock.content, context.codeBlock.language)
    }
}
#endif
