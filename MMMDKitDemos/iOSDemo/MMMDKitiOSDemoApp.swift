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
    private var messages: [MessageLayoutModel] = []
    private var streamingMessages: [MessageLayoutModel] = []
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
                    Task { @MainActor in
                        UIApplication.shared.open(url)
                    }
                },
                onCopyCode: { [weak self] _, _ in
                    Task { @MainActor in
                        self?.showToast(message: "已复制代码块")
                    }
                },
                onCopyTable: { [weak self] _ in
                    Task { @MainActor in
                        self?.showToast(message: "已复制表格")
                    }
                },
                onImageTap: { [weak self] imageBlock in
                    Task { @MainActor in
                        self?.presentImagePreview(for: imageBlock)
                    }
                }
            ),
            codeHighlighter: KeywordCodeHighlighter(),
            imageLoader: DemoImageLoader(),
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
            addConversationButton.isHidden = true
            messages = DemoMarkdownSamples.makeChatMessages().map {
                let width = view.bounds.width
                let context = RenderContext(theme: configuration.theme, actions: configuration.actions, toolbarOptions: configuration.toolbarOptions, blockRendererRegistry: configuration.blockRendererRegistry, inlineRendererRegistry: configuration.inlineRendererRegistry, codeHighlighter: configuration.codeHighlighter, mathRenderer: configuration.mathRenderer, imageLoader: configuration.imageLoader, codeBlockMaximumWidth: configuration.codeBlockMaximumWidth)
                return MessageLayoutModel(message: $0, layout: AsyncLayoutEngine.build(message: $0, configuration: configuration, containerWidth: width, context: context))
            }
            transcriptCollectionView.reloadData()
            scrollToBottom(animated: false)
        } else {
            addConversationButton.isHidden = false
            messages = streamingMessages
            transcriptCollectionView.reloadData()
            scrollToBottom(animated: false)
            
            if streamingMessages.isEmpty {
                appendStreamingConversation(isInitial: true)
                startStreaming(resetTranscript: false)
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

    private func presentImagePreview(for imageBlock: ImageBlock) {
        guard let url = imageBlock.url, let imageLoader = configuration.imageLoader else {
            showToast(message: "图片不可预览")
            return
        }

        Task {
            guard
                let data = try? await imageLoader.loadImageData(from: url),
                let image = UIImage(data: data)
            else {
                await MainActor.run {
                    self.showToast(message: "图片加载失败")
                }
                return
            }

            await MainActor.run {
                let previewController = UIViewController()
                previewController.view.backgroundColor = .black

                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.accessibilityLabel = imageBlock.alt
                imageView.translatesAutoresizingMaskIntoConstraints = false
                previewController.view.addSubview(imageView)

                let closeButton = UIButton(type: .system)
                closeButton.setTitle("关闭", for: .normal)
                closeButton.tintColor = .white
                closeButton.addAction(UIAction { [weak previewController] _ in
                    previewController?.dismiss(animated: true)
                }, for: .touchUpInside)
                closeButton.translatesAutoresizingMaskIntoConstraints = false
                previewController.view.addSubview(closeButton)

                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: previewController.view.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: previewController.view.trailingAnchor),
                    imageView.topAnchor.constraint(equalTo: previewController.view.topAnchor),
                    imageView.bottomAnchor.constraint(equalTo: previewController.view.bottomAnchor),
                    closeButton.trailingAnchor.constraint(equalTo: previewController.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                    closeButton.topAnchor.constraint(equalTo: previewController.view.safeAreaLayoutGuide.topAnchor, constant: 16)
                ])

                previewController.modalPresentationStyle = .fullScreen
                self.present(previewController, animated: true)
            }
        }
    }

    private func showChatFeed() {
        if messages.isEmpty {
            let width = view.bounds.width
            let context = RenderContext(theme: configuration.theme, actions: configuration.actions, toolbarOptions: configuration.toolbarOptions, blockRendererRegistry: configuration.blockRendererRegistry, inlineRendererRegistry: configuration.inlineRendererRegistry, codeHighlighter: configuration.codeHighlighter, mathRenderer: configuration.mathRenderer, imageLoader: configuration.imageLoader, codeBlockMaximumWidth: configuration.codeBlockMaximumWidth)
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                let samples = DemoMarkdownSamples.makeChatMessages()
                let models = samples.map { MessageLayoutModel(message: $0, layout: AsyncLayoutEngine.build(message: $0, configuration: self.configuration, containerWidth: width, context: context)) }
                DispatchQueue.main.async {
                    self.messages = models
                    self.transcriptCollectionView.reloadData()
                    self.scrollToBottom(animated: false)
                }
            }
        } else {
            transcriptCollectionView.reloadData()
            scrollToBottom(animated: false)
        }
    }

    private func startStreaming(resetTranscript: Bool) {
        streamingTimer?.invalidate()
        if resetTranscript {
            streamingMessages.removeAll()
            messages.removeAll()
            transcriptCollectionView.reloadData()
        }
        
        if streamingMessages.isEmpty {
            appendStreamingConversation(isInitial: resetTranscript)
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

        let width = view.bounds.width
        let context = RenderContext(theme: configuration.theme, actions: configuration.actions, toolbarOptions: configuration.toolbarOptions, blockRendererRegistry: configuration.blockRendererRegistry, inlineRendererRegistry: configuration.inlineRendererRegistry, codeHighlighter: configuration.codeHighlighter, mathRenderer: configuration.mathRenderer, imageLoader: configuration.imageLoader, codeBlockMaximumWidth: configuration.codeBlockMaximumWidth)
        let uModel = MessageLayoutModel(message: userMessage, layout: AsyncLayoutEngine.build(message: userMessage, configuration: configuration, containerWidth: width, context: context))
        let aModel = MessageLayoutModel(message: assistant, layout: AsyncLayoutEngine.build(message: assistant, configuration: configuration, containerWidth: width, context: context))
        let insertionStart = streamingMessages.count
        streamingMessages.append(uModel)
        streamingMessages.append(aModel)

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
        
        guard let index = targetArray.lastIndex(where: { $0.message.id == currentStreamingAssistantID }) else {
            return
        }
        
        let newMessage = DemoChatMessage(
            id: currentStreamingAssistantID,
            role: .assistant,
            title: "AI 助手 \(String(format: "%02d", streamingConversationIndex))",
            markdown: document.source,
            document: document
        )
        
        let width = view.bounds.width
        let context = RenderContext(theme: configuration.theme, actions: configuration.actions, toolbarOptions: configuration.toolbarOptions, blockRendererRegistry: configuration.blockRendererRegistry, inlineRendererRegistry: configuration.inlineRendererRegistry, codeHighlighter: configuration.codeHighlighter, mathRenderer: configuration.mathRenderer, imageLoader: configuration.imageLoader, codeBlockMaximumWidth: configuration.codeBlockMaximumWidth)
        let newModel = MessageLayoutModel(message: newMessage, layout: AsyncLayoutEngine.build(message: newMessage, configuration: configuration, containerWidth: width, context: context))
        
        targetArray[index] = newModel
        
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

private final class DemoImageLoader: ImageLoader, @unchecked Sendable {
    func loadImageData(from url: URL) async throws -> Data {
        guard url.scheme == "mmmd-demo" else {
            return try Data(contentsOf: url)
        }

        let title = url.lastPathComponent == "architecture" ? "MMMDKit" : "Image Block"
        let subtitle = url.lastPathComponent == "architecture" ? "Parser -> Model -> Native View" : "Local Demo ImageLoader"
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 720, height: 360))
        let image = renderer.image { _ in
            UIColor(red: 0.07, green: 0.12, blue: 0.22, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 720, height: 360)).fill()

            UIColor(red: 0.18, green: 0.42, blue: 0.92, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 48, y: 56, width: 624, height: 248), cornerRadius: 32).fill()

            UIColor(red: 0.41, green: 0.76, blue: 1, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 520, y: 36, width: 140, height: 140)).fill()

            (title as NSString).draw(
                in: CGRect(x: 84, y: 104, width: 552, height: 72),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
            )
            (subtitle as NSString).draw(
                in: CGRect(x: 86, y: 188, width: 552, height: 48),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 25, weight: .medium),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.86)
                ]
            )
        }

        guard let data = image.pngData() else {
            throw URLError(.cannotDecodeContentData)
        }
        return data
    }
}

extension DemoMarkdownViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatMessageCell.reuseIdentifier, for: indexPath) as! ChatMessageCell
        let isStreaming = modeControl.selectedSegmentIndex == 1
        let targetArray = isStreaming ? streamingMessages : messages
        let model = targetArray[indexPath.item]
        
        // Removed viewCache, creating a new AsyncChatMessageBubbleView every time
        let bubble = AsyncChatMessageBubbleView(layout: model.layout)
        
        let context = RenderContext(
            theme: configuration.theme,
            actions: configuration.actions,
            toolbarOptions: configuration.toolbarOptions,
            blockRendererRegistry: configuration.blockRendererRegistry,
            inlineRendererRegistry: configuration.inlineRendererRegistry,
            codeHighlighter: configuration.codeHighlighter,
            mathRenderer: configuration.mathRenderer,
            imageLoader: configuration.imageLoader,
            codeBlockMaximumWidth: configuration.codeBlockMaximumWidth
        )
        
        cell.host(bubble, width: model.layout.targetWidth, role: model.message.role)
        bubble.configure(model: model, configuration: configuration, context: context)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let isStreaming = modeControl.selectedSegmentIndex == 1
        let targetArray = isStreaming ? streamingMessages : messages
        guard indexPath.item < targetArray.count else { return .zero }
        let model = targetArray[indexPath.item]
        return CGSize(width: collectionView.bounds.width, height: model.layout.exactHeight)
    }
}

private final class ChatMessageCell: UICollectionViewCell {
    static let reuseIdentifier = "MMMDKit.ChatMessageCell"
    private var hostedBubble: AsyncChatMessageBubbleView?
    private var activeConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func host(_ bubble: AsyncChatMessageBubbleView, width: CGFloat, role: DemoChatMessage.Role) {
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

private struct AsyncBubbleLayout {
    let id = UUID()
    let attributedText: NSAttributedString
    let placeholders: [Placeholder]
    let targetWidth: CGFloat
    let exactHeight: CGFloat
    let textContainer: NSTextContainer
    let layoutManager: NSLayoutManager
    let textStorage: NSTextStorage
    
    struct Placeholder {
        let range: NSRange
        let block: MarkdownBlock
        let exactFrame: CGRect
    }
}

private struct MessageLayoutModel {
    let message: DemoChatMessage
    let layout: AsyncBubbleLayout
}

private final class AsyncLayoutEngine {
    static func build(message: DemoChatMessage, configuration: MarkdownConfiguration, containerWidth: CGFloat, context: RenderContext) -> AsyncBubbleLayout {
        let maxAllowedWidth = containerWidth * 0.9
        let resultString = NSMutableAttributedString()
        var placeholders: [AsyncBubbleLayout.Placeholder] = []
        var currentTextBlocks: [MarkdownBlock] = []
        
        func flushTextBlocks() {
            guard !currentTextBlocks.isEmpty else { return }
            let attr = TextBlockView.attributedString(for: currentTextBlocks, context: context, cacheKey: nil, textColor: .label, listLevel: 0, blockquoteLevel: 0)
            resultString.append(attr)
            currentTextBlocks.removeAll()
        }
        
        for (blockIndex, block) in message.document.blocks.enumerated() {
            switch block {
            case .heading, .paragraph, .list:
                currentTextBlocks.append(block)
                continue
            default:
                flushTextBlocks()
            }
            
            let hasPreviousContent = resultString.length > 0
            if hasPreviousContent && resultString.string.last != "\n" {
                resultString.append(NSAttributedString(string: "\n"))
            }
            
            var blockWidth: CGFloat = maxAllowedWidth - 28
            var blockHeight: CGFloat = 0
            
            switch block {
            case .code(let codeBlock):
                blockHeight = CodeBlockView.exactHeight(for: codeBlock, width: blockWidth, context: context)
            case .table(let table):
                let minCellWidth: CGFloat = 132
                let columnCount = max((table.rows.map(\.count).max() ?? 0), table.header.count, 1)
                let contentWidth = CGFloat(columnCount) * minCellWidth
                blockWidth = min(contentWidth, maxAllowedWidth - 28)
                blockHeight = TableBlockView.exactHeight(for: table, width: blockWidth, context: context)
            case .math(let mathBlock):
                blockHeight = MathBlockView.exactHeight(for: mathBlock, width: blockWidth, context: context)
            case .html(let htmlBlock):
                blockHeight = HTMLBlockView.exactHeight(for: htmlBlock, width: blockWidth, context: context)
            case .image(let imageBlock):
                blockHeight = ImageBlockView.exactHeight(for: imageBlock, width: blockWidth, context: context)
            case .blockquote(let blocks):
                blockHeight = BlockquoteBlockView.exactHeight(for: blocks, width: blockWidth, context: context)
            case .thematicBreak:
                blockHeight = ThematicBreakView.exactHeight(context: context)
            default:
                break
            }
            
            let attachment = NSTextAttachment()
            attachment.bounds = CGRect(x: 0, y: 0, width: blockWidth, height: blockHeight)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
            attachment.image = renderer.image { _ in }
            
            let hasFollowingContent = blockIndex + 1 < message.document.blocks.count
            let attachString = NSMutableAttributedString(string: hasFollowingContent ? "\u{FFFC}\n" : "\u{FFFC}")
            attachString.addAttribute(.attachment, value: attachment, range: NSRange(location: 0, length: 1))

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.paragraphSpacingBefore = hasPreviousContent ? context.theme.spacing.blockSpacing : 0
            paragraphStyle.paragraphSpacing = Self.needsTrailingSpacing(after: blockIndex, in: message.document.blocks) ? context.theme.spacing.blockSpacing : 0
            attachString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attachString.length))
            
            let range = NSRange(location: resultString.length, length: 1)
            resultString.append(attachString)
            
            placeholders.append(.init(range: range, block: block, exactFrame: .zero))
        }
        flushTextBlocks()
        
        let textStorage = NSTextStorage(attributedString: resultString)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: maxAllowedWidth - 28, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)
        
        let usedRect = layoutManager.usedRect(for: textContainer)
        let finalWidth = min(ceil(usedRect.width) + 28, maxAllowedWidth)
        
        let titleFont = UIFont.preferredFont(forTextStyle: .caption1)
        let titleHeight = ceil(titleFont.lineHeight)
        let textY = 10 + titleHeight + 8
        
        let finalHeight = textY + ceil(usedRect.height) + 12
        
        var updatedPlaceholders: [AsyncBubbleLayout.Placeholder] = []
        for p in placeholders {
            let glyphRange = layoutManager.glyphRange(forCharacterRange: p.range, actualCharacterRange: nil)
            var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            rect.origin.x += 14 // left padding in textView
            
            updatedPlaceholders.append(.init(range: p.range, block: p.block, exactFrame: rect))
        }
        
        return AsyncBubbleLayout(attributedText: resultString, placeholders: updatedPlaceholders, targetWidth: finalWidth, exactHeight: finalHeight, textContainer: textContainer, layoutManager: layoutManager, textStorage: textStorage)
    }

    private static func needsTrailingSpacing(after index: Int, in blocks: [MarkdownBlock]) -> Bool {
        guard index + 1 < blocks.count else { return false }
        switch blocks[index + 1] {
        case .heading, .paragraph, .list:
            return true
        default:
            return false
        }
    }
}

private final class AsyncChatMessageBubbleView: UIView {
    private let bubbleView = UIView()
    private let titleLabel = UILabel()
    private let markdownView = MarkdownView()
    var layoutID: UUID?
    
    init(layout: AsyncBubbleLayout) {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    func configure(model: MessageLayoutModel, configuration: MarkdownConfiguration, context: RenderContext) {
        if layoutID == model.layout.id { return }
        layoutID = model.layout.id
        
        titleLabel.text = model.message.title
        bubbleView.backgroundColor = backgroundColor(for: model.message.role)
        markdownView.configuration = configuration
        markdownView.render(model.message.document)
        setNeedsLayout()
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