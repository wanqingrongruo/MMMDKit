import AppKit
import MMMDCore
import MMMDAppKit

final class ChatMessageItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("MMMDKit.ChatMessageItem")

    override func loadView() {
        view = ChatMessageRowView()
    }

    func configure(message: DemoChatMessage, configuration: MarkdownConfiguration) {
        (view as? ChatMessageRowView)?.configure(message: message, configuration: configuration)
    }
}

final class ChatMessageRowView: NSView {
    private let bubbleView = NSView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let markdownView = MarkdownNSView()
    private var alignmentConstraints: [NSLayoutConstraint] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func configure(message: DemoChatMessage, configuration: MarkdownConfiguration) {
        titleLabel.stringValue = message.title
        bubbleView.layer?.backgroundColor = backgroundColor(for: message.role).cgColor
        markdownView.configuration = configuration
        markdownView.render(message.document)
        markdownView.invalidateIntrinsicContentSize()

        NSLayoutConstraint.deactivate(alignmentConstraints)
        switch message.role {
        case .assistant:
            alignmentConstraints = [
                bubbleView.leadingAnchor.constraint(equalTo: leadingAnchor),
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
            ]
        case .user:
            alignmentConstraints = [
                bubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
                bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor)
            ]
        }
        NSLayoutConstraint.activate(alignmentConstraints)
        needsLayout = true
    }

    static func estimatedHeight(for message: DemoChatMessage, width: CGFloat, configuration: MarkdownConfiguration) -> CGFloat {
        let bubbleWidth = max(1, width * 0.82 - 28)
        let markdownHeight = MarkdownNSView.estimatedHeight(for: message.document, width: bubbleWidth, configuration: configuration)
        return max(44, ceil(10 + 14 + 8 + markdownHeight + 12))
    }

    private func setupView() {
        bubbleView.wantsLayer = true
        bubbleView.layer?.cornerRadius = 14
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bubbleView)

        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(titleLabel)

        markdownView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(markdownView)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.82),

            titleLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: bubbleView.trailingAnchor, constant: -14),
            titleLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),

            markdownView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            markdownView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            markdownView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            markdownView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }

    private func backgroundColor(for role: DemoChatMessage.Role) -> NSColor {
        switch role {
        case .assistant:
            return NSColor.controlBackgroundColor
        case .user:
            return NSColor.controlAccentColor.withAlphaComponent(0.22)
        }
    }
}
