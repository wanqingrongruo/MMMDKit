import UIKit
import MMMDCore
import MMMDHighlighter
import MMMDParserCmark
import MMMDStreaming
import MMMDUIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        true
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: DemoMarkdownViewController())
        window.makeKeyAndVisible()
        self.window = window
    }
}

final class DemoMarkdownViewController: UIViewController {
    private let transcriptCollectionView: UICollectionView
    private lazy var modeControl = UISegmentedControl(items: ["30+ 数据", "流式输出"])
    private let addConversationButton = UIButton(type: .system)
    private var configuration: MarkdownConfiguration!
    private var messages: [DemoChatMessage] = []
    private var streamingMessages: [DemoChatMessage] = []
    private var streamingProcessor: StreamingMarkdownProcessor?
    private var streamingTimer: Timer?
    private var streamingChunks: [String] = []
    private var streamingIndex = 0
    private var pendingStreamingDocument: MarkdownDocument?
    private var streamingUpdateWorkItem: DispatchWorkItem?
    private let streamingUpdateInterval: TimeInterval = 0.09
    private var streamingConversationIndex = 0
    private var currentStreamingAssistantID: String?
    private var isApplyingStreamingReload = false

    private var viewCache: [String: ChatMessageBubbleView] = [:]

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 0
        layout.estimatedItemSize = .zero
        transcriptCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 0
        layout.estimatedItemSize = .zero
        transcriptCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MMMDKit iOS Demo"
        view.backgroundColor = .systemBackground

        modeControl.selectedSegmentIndex = 0
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        modeControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modeControl)

        addConversationButton.setTitle("新增对话", for: .normal)
        addConversationButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        addConversationButton.addTarget(self, action: #selector(addConversationTapped), for: .touchUpInside)
        addConversationButton.isHidden = true
        addConversationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addConversationButton)

        setupTranscriptCollectionView()
        NSLayoutConstraint.activate([
            transcriptCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            transcriptCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            modeControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            modeControl.trailingAnchor.constraint(equalTo: addConversationButton.leadingAnchor, constant: -8),
            modeControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            addConversationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            addConversationButton.centerYAnchor.constraint(equalTo: modeControl.centerYAnchor),
            transcriptCollectionView.topAnchor.constraint(equalTo: modeControl.bottomAnchor, constant: 16),
            transcriptCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        configuration = MarkdownConfiguration(
            actions: .init(
                onLinkTap: { url in
                    UIApplication.shared.open(url)
                },
                onCopyCode: { [weak self] _, _ in
                    self?.showToast(message: "已复制代码块")
                },
                onCopyTable: { [weak self] _ in
                    self?.showToast(message: "已复制表格")
                }
            ),
            codeHighlighter: KeywordCodeHighlighter(),
            codeBlockMaximumWidth: 640
        )
        showChatFeed()
    }

    deinit {
        streamingTimer?.invalidate()
        streamingUpdateWorkItem?.cancel()
    }

    @objc private func modeChanged() {
        if modeControl.selectedSegmentIndex == 0 {
            // Switch to static feed
            streamingMessages = messages
            showChatFeed()
        } else {
            // Switch to streaming feed
            addConversationButton.isHidden = false
            messages = streamingMessages
            transcriptCollectionView.collectionViewLayout.invalidateLayout()
            transcriptCollectionView.reloadData()
            
            if messages.isEmpty || currentStreamingAssistantID == nil {
                startStreaming(resetTranscript: true)
            } else {
                // If there's an ongoing stream or existing messages, just let them see it
                scrollToBottom(animated: false)
            }
        }
    }

    @objc private func addConversationTapped() {
        appendStreamingConversation(isInitial: false)
    }

    private func setupTranscriptCollectionView() {
        transcriptCollectionView.backgroundColor = .clear
        transcriptCollectionView.alwaysBounceVertical = true
        transcriptCollectionView.dataSource = self
        transcriptCollectionView.delegate = self
        transcriptCollectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: ChatMessageCell.reuseIdentifier)
        transcriptCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transcriptCollectionView)
    }

    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textAlignment = .center
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
        
        UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }

    private func showChatFeed() {
        addConversationButton.isHidden = true
        messages = DemoMarkdownSamples.chatMessages
        transcriptCollectionView.collectionViewLayout.invalidateLayout()
        transcriptCollectionView.reloadData()
    }

    private func startStreaming(resetTranscript: Bool) {
        streamingTimer?.invalidate()
        streamingUpdateWorkItem?.cancel()
        streamingUpdateWorkItem = nil
        pendingStreamingDocument = nil
        isApplyingStreamingReload = false
        addConversationButton.isHidden = false
        
        var isInitial = false
        if resetTranscript {
            streamingConversationIndex = 0
            currentStreamingAssistantID = nil
            messages.removeAll()
            streamingMessages.removeAll()
            isInitial = true
        }
        appendStreamingConversation(isInitial: isInitial)
    }

    private func appendStreamingConversation(isInitial: Bool) {
        streamingTimer?.invalidate()
        streamingUpdateWorkItem?.cancel()
        streamingUpdateWorkItem = nil
        pendingStreamingDocument = nil
        isApplyingStreamingReload = false

        streamingConversationIndex += 1
        let userMessage = DemoMarkdownSamples.makeStreamingUserMessage(index: streamingConversationIndex)
        let assistant = DemoMarkdownSamples.makeStreamingAssistantPlaceholder(index: streamingConversationIndex)
        currentStreamingAssistantID = assistant.id

        let insertionStart = streamingMessages.count
        streamingMessages.append(userMessage)
        streamingMessages.append(assistant)

        let shouldUpdateUI = modeControl.selectedSegmentIndex == 1
        if shouldUpdateUI {
            messages = streamingMessages
            if isInitial {
                transcriptCollectionView.collectionViewLayout.invalidateLayout()
                transcriptCollectionView.reloadData()
                DispatchQueue.main.async { [weak self] in
                    self?.scrollToBottom(animated: false)
                }
            } else {
                let insertedIndexPaths = [
                    IndexPath(item: insertionStart, section: 0),
                    IndexPath(item: insertionStart + 1, section: 0)
                ]
                transcriptCollectionView.performBatchUpdates {
                    transcriptCollectionView.insertItems(at: insertedIndexPaths)
                } completion: { [weak self] _ in
                    self?.scrollToBottom(animated: true)
                }
            }
        }

        streamingChunks = DemoMarkdownSamples.streamingChunks()
        streamingIndex = 0
        let processor = StreamingMarkdownProcessor(parser: CmarkMarkdownParser())
        processor.onDiff = { [weak self] diff in
            DispatchQueue.main.async {
                guard let self else { return }
                self.scheduleStreamingAssistantUpdate(with: diff.document)
            }
        }
        streamingProcessor = processor
        processor.reset()

        streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            guard self.streamingIndex < self.streamingChunks.count else {
                self.streamingProcessor?.finish()
                timer.invalidate()
                return
            }

            self.streamingProcessor?.append(self.streamingChunks[self.streamingIndex])
            self.streamingIndex += 1
        }
    }

    private func scheduleStreamingAssistantUpdate(with document: MarkdownDocument) {
        pendingStreamingDocument = document
        guard streamingUpdateWorkItem == nil else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.applyPendingStreamingAssistantUpdate()
        }
        streamingUpdateWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .milliseconds(Int(streamingUpdateInterval * 1000)),
            execute: workItem
        )
    }

    private func applyPendingStreamingAssistantUpdate() {
        streamingUpdateWorkItem = nil
        guard let document = pendingStreamingDocument else {
            return
        }
        pendingStreamingDocument = nil
        replaceStreamingAssistant(with: document)
    }

    private func replaceStreamingAssistant(with document: MarkdownDocument) {
        guard !isApplyingStreamingReload else {
            scheduleStreamingAssistantUpdate(with: document)
            return
        }
        guard let currentStreamingAssistantID else { return }
        
        let shouldUpdateUI = modeControl.selectedSegmentIndex == 1
        var targetArray = shouldUpdateUI ? messages : streamingMessages
        
        guard let index = targetArray.lastIndex(where: { $0.id == currentStreamingAssistantID }) else {
            return
        }
        
        let newMessage = DemoChatMessage(
            id: currentStreamingAssistantID,
            role: .assistant,
            title: "AI 助手 \(String(format: "%02d", streamingConversationIndex))",
            markdown: document.source,
            document: document
        )
        
        targetArray[index] = newMessage
        
        if shouldUpdateUI {
            messages = targetArray
            streamingMessages = targetArray
            let shouldPinToBottom = isNearBottom()
            let indexPath = IndexPath(item: index, section: 0)
            isApplyingStreamingReload = true
            UIView.performWithoutAnimation {
                transcriptCollectionView.performBatchUpdates {
                    transcriptCollectionView.collectionViewLayout.invalidateLayout()
                    transcriptCollectionView.reloadItems(at: [indexPath])
                } completion: { [weak self] _ in
                    guard let self else { return }
                    self.isApplyingStreamingReload = false
                    if shouldPinToBottom {
                        self.scrollToBottom(animated: false)
                    }
                }
            }
        } else {
            streamingMessages = targetArray
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        transcriptCollectionView.layoutIfNeeded()
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        transcriptCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }

    private func isNearBottom(threshold: CGFloat = 72) -> Bool {
        let visibleBottom = transcriptCollectionView.contentOffset.y
            + transcriptCollectionView.bounds.height
            - transcriptCollectionView.adjustedContentInset.bottom
        return transcriptCollectionView.contentSize.height - visibleBottom <= threshold
    }
}

extension DemoMarkdownViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatMessageCell.reuseIdentifier, for: indexPath) as? ChatMessageCell ?? ChatMessageCell()
        let message = messages[indexPath.item]
        
        let bubble: ChatMessageBubbleView
        if let cached = viewCache[message.id] {
            bubble = cached
        } else {
            bubble = ChatMessageBubbleView()
            viewCache[message.id] = bubble
        }
        
        cell.host(bubble)
        bubble.configure(message: message, configuration: configuration, containerWidth: collectionView.bounds.width)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = max(1, collectionView.bounds.width)
        let height = ChatMessageBubbleView.estimatedHeight(for: messages[indexPath.item], width: width, configuration: configuration)
        return CGSize(width: width, height: height)
    }
}

private final class ChatMessageCell: UICollectionViewCell {
    static let reuseIdentifier = "MMMDKit.ChatMessageCell"
    private var hostedBubble: ChatMessageBubbleView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func host(_ bubble: ChatMessageBubbleView) {
        if hostedBubble == bubble { return }
        hostedBubble?.removeFromSuperview()
        hostedBubble = bubble
        bubble.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubble)
        let bottomConstraint = bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomConstraint.priority = .init(999)
        NSLayoutConstraint.activate([
            bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomConstraint
        ])
    }
}

private final class ChatMessageBubbleView: UIView {
    private static var widthCache = NSCache<NSString, NSNumber>()

    private let bubbleView = UIView()
    private let titleLabel = UILabel()
    private let markdownView = MarkdownView()
    private var alignmentConstraints: [NSLayoutConstraint] = []
    private var currentRole: DemoChatMessage.Role?
    private var currentMessageID: String?
    private var currentDocumentSourceCount: Int = -1
    private var maxBubbleWidth: CGFloat = 0
    private var minWidthConstraint: NSLayoutConstraint?
    private var maxWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func configure(message: DemoChatMessage, configuration: MarkdownConfiguration, containerWidth: CGFloat) {
        let isSameMessage = message.id == currentMessageID
        let isSameDocument = message.document.source.count == currentDocumentSourceCount

        if !isSameMessage || !isSameDocument {
            titleLabel.text = message.title
            bubbleView.backgroundColor = backgroundColor(for: message.role)
            markdownView.configuration = configuration
            markdownView.render(message.document)
            markdownView.invalidateIntrinsicContentSize()
            
            currentMessageID = message.id
            currentDocumentSourceCount = message.document.source.count
            maxBubbleWidth = 0
            minWidthConstraint?.isActive = false
        }
        
        let allowedMaxWidth = containerWidth * 0.9
        let cacheKey = "\(message.id)_\(allowedMaxWidth)_\(message.document.source.count)" as NSString
        let targetWidth: CGFloat
        if let cached = Self.widthCache.object(forKey: cacheKey) {
            targetWidth = CGFloat(cached.floatValue)
        } else {
            maxWidthConstraint?.isActive = false
            let unconstrainedSize = bubbleView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            maxWidthConstraint?.isActive = true
            targetWidth = min(unconstrainedSize.width, allowedMaxWidth)
            Self.widthCache.setObject(NSNumber(value: Float(targetWidth)), forKey: cacheKey)
        }
        
        if targetWidth > maxBubbleWidth {
            maxBubbleWidth = targetWidth
            minWidthConstraint?.isActive = false
            let constraint = bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: maxBubbleWidth)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            minWidthConstraint = constraint
        }

        guard currentRole != message.role else {
            setNeedsLayout()
            return
        }
        currentRole = message.role
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
        setNeedsLayout()
    }

    private func setupView() {
        bubbleView.layer.cornerRadius = 14
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bubbleView)

        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(titleLabel)

        markdownView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(markdownView)

        let bubbleBottomConstraint = bubbleView.bottomAnchor.constraint(equalTo: bottomAnchor)
        bubbleBottomConstraint.priority = .init(999)
        
        let maxWidthConst = bubbleView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.9)
        maxWidthConstraint = maxWidthConst

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: topAnchor),
            bubbleBottomConstraint,
            maxWidthConst,

            titleLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: bubbleView.trailingAnchor, constant: -14),
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
                traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.16, alpha: 1.0) : UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
            }
        case .user:
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.33, blue: 0.90, alpha: 0.3) : UIColor(red: 0.91, green: 0.95, blue: 1.0, alpha: 1.0)
            }
        }
    }

    private static var bubbleHeightCache = NSCache<NSString, NSNumber>()
    private static let sizingBubble = ChatMessageBubbleView()

    static func estimatedHeight(for message: DemoChatMessage, width: CGFloat, configuration: MarkdownConfiguration) -> CGFloat {
        let cacheKey = "\(message.id)_\(width)_\(message.document.source.count)" as NSString
        if let cached = bubbleHeightCache.object(forKey: cacheKey) {
            return CGFloat(cached.floatValue)
        }
        
        sizingBubble.configure(message: message, configuration: configuration, containerWidth: width)
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let size = sizingBubble.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        let totalHeight = ceil(size.height)
        bubbleHeightCache.setObject(NSNumber(value: Float(totalHeight)), forKey: cacheKey)
        return totalHeight
    }
}
