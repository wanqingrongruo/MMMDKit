import AppKit
import MMMDCore
import MMMDAppKit

final class ChatMessageItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("MMMDKit.ChatMessageItem")

    override func loadView() {
        view = ChatMessageRowView()
    }

    func configure(model: MacMessageLayoutModel, configuration: MarkdownConfiguration) {
        (view as? ChatMessageRowView)?.configure(model: model, configuration: configuration)
    }
}

struct MacMessageLayoutModel {
    let message: DemoChatMessage
    let layout: MacChatBubbleLayout
}

struct MacChatBubbleLayout {
    let id = UUID()
    let targetWidth: CGFloat
    let exactHeight: CGFloat
    let markdownLayout: MarkdownLayoutResult
}

enum MacChatBubbleLayoutEngine {
    private static let horizontalPadding: CGFloat = 28
    private static let topPadding: CGFloat = 10
    private static let titleSpacing: CGFloat = 8
    private static let bottomPadding: CGFloat = 12
    private static let maximumWidthRatio: CGFloat = 0.82

    static func build(message: DemoChatMessage, configuration: MarkdownConfiguration, containerWidth: CGFloat) -> MacChatBubbleLayout {
        let maxAllowedWidth = max(1, containerWidth * maximumWidthRatio)
        let markdownLayout = MarkdownLayoutEngine.measure(
            document: message.document,
            fittingWidth: max(1, maxAllowedWidth - horizontalPadding),
            configuration: configuration
        )
        let titleFont = NSFont.preferredFont(forTextStyle: .caption1)
        let titleHeight = ceil(titleFont.ascender - titleFont.descender + titleFont.leading)
        let textY = topPadding + titleHeight + titleSpacing
        return MacChatBubbleLayout(
            targetWidth: maxAllowedWidth,
            exactHeight: textY + markdownLayout.size.height + bottomPadding,
            markdownLayout: markdownLayout
        )
    }
}

final class ChatMessageRowView: NSView {
    private let bubbleView = NSView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let markdownView = MarkdownNSView()
    private var alignmentConstraints: [NSLayoutConstraint] = []
    private var layoutID: UUID?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func configure(model: MacMessageLayoutModel, configuration: MarkdownConfiguration) {
        guard layoutID != model.layout.id else { return }
        layoutID = model.layout.id

        titleLabel.stringValue = model.message.title
        bubbleView.layer?.backgroundColor = backgroundColor(for: model.message.role).cgColor
        markdownView.configuration = configuration
        markdownView.render(model.message.document)

        NSLayoutConstraint.deactivate(alignmentConstraints)
        let widthConstraint = bubbleView.widthAnchor.constraint(equalToConstant: model.layout.targetWidth)
        widthConstraint.priority = .init(999)
        switch model.message.role {
        case .assistant:
            alignmentConstraints = [
                widthConstraint,
                bubbleView.leadingAnchor.constraint(equalTo: leadingAnchor),
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
            ]
        case .user:
            alignmentConstraints = [
                widthConstraint,
                bubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
                bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor)
            ]
        }
        NSLayoutConstraint.activate(alignmentConstraints)
        needsLayout = true
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
