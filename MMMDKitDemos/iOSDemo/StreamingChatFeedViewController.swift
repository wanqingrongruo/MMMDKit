import UIKit
import MMMDCore
import MMMDParserCmark
import MMMDStreaming

final class StreamingChatFeedViewController: ChatFeedViewController {
    private var streamingSession: StreamingMarkdownSession?
    private var streamingTimer: Timer?
    private var streamingChunks: [String] = []
    private var streamingIndex = 0
    private var pendingStreamingDocument: MarkdownDocument?
    private var streamingConversationIndex = 0
    private var currentStreamingAssistantID: String?
    private var isApplyingStreamingReload = false
    private var didStartInitialConversation = false

    init() {
        super.init(title: "流式输出")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        title = "流式输出"
    }

    deinit {
        streamingTimer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "新增对话",
            style: .plain,
            target: self,
            action: #selector(addConversationTapped)
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didStartInitialConversation, view.bounds.width > 0 else { return }
        didStartInitialConversation = true
        appendStreamingConversation(isInitial: true)
    }

    @objc private func addConversationTapped() {
        appendStreamingConversation(isInitial: false)
    }

    private func appendStreamingConversation(isInitial: Bool) {
        streamingTimer?.invalidate()
        pendingStreamingDocument = nil
        isApplyingStreamingReload = false

        streamingConversationIndex += 1
        let userMessage = DemoMarkdownSamples.makeStreamingUserMessage(index: streamingConversationIndex)
        let assistant = DemoMarkdownSamples.makeStreamingAssistantPlaceholder(index: streamingConversationIndex)
        currentStreamingAssistantID = assistant.id

        let insertionStart = messages.count
        messages.append(buildLayoutModel(for: userMessage))
        messages.append(buildLayoutModel(for: assistant))

        if isInitial {
            invalidateTranscriptLayout()
            reloadTranscript()
            DispatchQueue.main.async { [weak self] in
                self?.scrollToBottom(animated: false)
            }
        } else {
            let insertedIndexPaths = [
                IndexPath(item: insertionStart, section: 0),
                IndexPath(item: insertionStart + 1, section: 0)
            ]
            insertItems(at: insertedIndexPaths) { [weak self] _ in
                self?.scrollToBottom(animated: true)
            }
        }

        startStreamingOutput()
    }

    private func startStreamingOutput() {
        streamingChunks = DemoMarkdownSamples.streamingChunks()
        streamingIndex = 0
        let session = StreamingMarkdownSession(parser: CmarkMarkdownParser(), updateInterval: 0.09)
        session.onUpdate = { [weak self] diff in
            self?.replaceStreamingAssistant(with: diff.document)
        }
        streamingSession = session
        session.reset()

        streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            guard self.streamingIndex < self.streamingChunks.count else {
                self.streamingSession?.finish()
                timer.invalidate()
                return
            }

            self.streamingSession?.append(self.streamingChunks[self.streamingIndex])
            self.streamingIndex += 1
        }
    }

    private func replaceStreamingAssistant(with document: MarkdownDocument) {
        guard !isApplyingStreamingReload else {
            pendingStreamingDocument = document
            return
        }
        guard let currentStreamingAssistantID,
              let index = messages.lastIndex(where: { $0.message.id == currentStreamingAssistantID }) else {
            return
        }

        let newMessage = DemoChatMessage(
            id: currentStreamingAssistantID,
            role: .assistant,
            title: "AI 助手 \(String(format: "%02d", streamingConversationIndex))",
            markdown: document.source,
            document: document
        )

        messages[index] = buildLayoutModel(for: newMessage)
        let shouldPinToBottom = isNearBottom()
        let indexPath = IndexPath(item: index, section: 0)
        isApplyingStreamingReload = true
        reloadItem(at: indexPath) { [weak self] _ in
            guard let self else { return }
            self.isApplyingStreamingReload = false
            if let pendingDocument = self.pendingStreamingDocument {
                self.pendingStreamingDocument = nil
                self.replaceStreamingAssistant(with: pendingDocument)
            } else if shouldPinToBottom {
                self.scrollToBottom(animated: false)
            }
        }
    }
}
