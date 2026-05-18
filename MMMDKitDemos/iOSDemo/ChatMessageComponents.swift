import UIKit
import MMMDCore
import MMMDUIKit

final class ChatMessageCell: UICollectionViewCell {
    static let reuseIdentifier = "MMMDKit.ChatMessageCell"
    private var hostedBubble: ChatMessageBubbleView?
    private var activeConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func host(_ bubble: ChatMessageBubbleView, width: CGFloat, role: DemoChatMessage.Role) {
        if hostedBubble == bubble { return }
        NSLayoutConstraint.deactivate(activeConstraints)
        activeConstraints.removeAll()
        hostedBubble?.removeFromSuperview()
        hostedBubble = bubble
        bubble.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubble)
        let bottomConstraint = bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomConstraint.priority = .init(999)
        let widthConstraint = bubble.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.priority = .init(999)
        let horizontalConstraint: NSLayoutConstraint
        switch role {
        case .assistant:
            horizontalConstraint = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        case .user:
            horizontalConstraint = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        }
        activeConstraints = [
            widthConstraint,
            horizontalConstraint,
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomConstraint
        ]
        NSLayoutConstraint.activate(activeConstraints)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        NSLayoutConstraint.deactivate(activeConstraints)
        activeConstraints.removeAll()
        hostedBubble?.removeFromSuperview()
        hostedBubble = nil
    }
}

struct MessageLayoutModel {
    let message: DemoChatMessage
    let layout: ChatBubbleLayout
}

struct ChatBubbleLayout {
    let id = UUID()
    let targetWidth: CGFloat
    let exactHeight: CGFloat
    let markdownLayout: MarkdownLayoutResult
}

enum ChatBubbleLayoutEngine {
    private static let horizontalPadding: CGFloat = 28
    private static let topPadding: CGFloat = 10
    private static let titleSpacing: CGFloat = 8
    private static let bottomPadding: CGFloat = 12
    private static let maximumWidthRatio: CGFloat = 0.9

    static func build(message: DemoChatMessage, configuration: MarkdownConfiguration, containerWidth: CGFloat) -> ChatBubbleLayout {
        let maxAllowedWidth = containerWidth * maximumWidthRatio
        let markdownLayout = MarkdownLayoutEngine.measure(
            document: message.document,
            fittingWidth: max(1, maxAllowedWidth - horizontalPadding),
            configuration: configuration
        )
        let finalWidth = min(markdownLayout.size.width + horizontalPadding, maxAllowedWidth)
        let titleFont = UIFont.preferredFont(forTextStyle: .caption1)
        let titleHeight = ceil(titleFont.lineHeight)
        let textY = topPadding + titleHeight + titleSpacing
        return ChatBubbleLayout(
            targetWidth: finalWidth,
            exactHeight: textY + markdownLayout.size.height + bottomPadding,
            markdownLayout: markdownLayout
        )
    }
}

final class ChatMessageBubbleView: UIView {
    private let bubbleView = UIView()
    private let titleLabel = UILabel()
    private let markdownView = MarkdownView()
    var layoutID: UUID?

    init(layout: ChatBubbleLayout) {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(model: MessageLayoutModel, configuration: MarkdownConfiguration) {
        if layoutID == model.layout.id { return }
        layoutID = model.layout.id

        titleLabel.text = model.message.title
        bubbleView.backgroundColor = backgroundColor(for: model.message.role)
        markdownView.configuration = configuration
        markdownView.render(model.message.document)
        setNeedsLayout()
    }

    private func setupView() {
        layer.drawsAsynchronously = true

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 14
        bubbleView.layer.drawsAsynchronously = true
        addSubview(bubbleView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel
        bubbleView.addSubview(titleLabel)

        markdownView.backgroundColor = .clear
        markdownView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(markdownView)

        NSLayoutConstraint.activate([
            bubbleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bubbleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bubbleView.topAnchor.constraint(equalTo: topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            titleLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),

            markdownView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            markdownView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            markdownView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            markdownView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -12)
        ])
    }

    private func backgroundColor(for role: DemoChatMessage.Role) -> UIColor {
        switch role {
        case .assistant:
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.2, alpha: 1.0) : UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1.0)
            }
        case .user:
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 0, green: 0.5, blue: 1.0, alpha: 1.0) : UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
            }
        }
    }
}
