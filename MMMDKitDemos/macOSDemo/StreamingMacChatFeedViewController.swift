import AppKit
import MMMDCore
import MMMDParserCmark
import MMMDStreaming

final class StreamingMacChatFeedViewController: MacChatFeedViewController {
    private let addConversationButton = NSButton(title: "新增对话", target: nil, action: nil)
    private var streamingSession: StreamingMarkdownSession?
    private var streamingTimer: Timer?
    private var streamingChunks: [String] = []
    private var streamingIndex = 0
    private var streamingConversationIndex = 0
    private var currentStreamingAssistantID: String?
    private var didStartInitialConversation = false

    override var headerView: NSView? { addConversationButton }

    deinit {
        streamingTimer?.invalidate()
    }

    override func viewDidLoad() {
        addConversationButton.target = self
        addConversationButton.action = #selector(addConversationTapped)
        addConversationButton.bezelStyle = .rounded
        super.viewDidLoad()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        guard !didStartInitialConversation, view.bounds.width > 0 else { return }
        didStartInitialConversation = true
        appendStreamingConversation()
    }

    @objc private func addConversationTapped() {
        appendStreamingConversation()
    }

    private func appendStreamingConversation() {
        streamingTimer?.invalidate()

        streamingConversationIndex += 1
        let assistant = DemoMarkdownSamples.makeStreamingAssistantPlaceholder(index: streamingConversationIndex)
        currentStreamingAssistantID = assistant.id
        let insertionStart = messages.count
        messages.append(DemoMarkdownSamples.makeStreamingUserMessage(index: streamingConversationIndex))
        messages.append(assistant)
        let insertedIndexPaths: Set<IndexPath> = [
            IndexPath(item: insertionStart, section: 0),
            IndexPath(item: insertionStart + 1, section: 0)
        ]
        insertItems(at: insertedIndexPaths)
        scrollToBottom()
        startStreamingOutput()
    }

    private func startStreamingOutput() {
        streamingChunks = DemoMarkdownSamples.streamingChunks()
        streamingIndex = 0
        let session = StreamingMarkdownSession(parser: CmarkMarkdownParser(), updateInterval: 0.045)
        session.onUpdate = { [weak self] diff in
            self?.replaceStreamingAssistant(with: diff.document)
        }
        streamingSession = session
        session.reset()

        streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.045, repeats: true) { [weak self] timer in
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
        guard let currentStreamingAssistantID,
              let index = messages.lastIndex(where: { $0.id == currentStreamingAssistantID }) else {
            return
        }
        messages[index] = DemoChatMessage(
            id: currentStreamingAssistantID,
            role: .assistant,
            title: "AI 助手 \(String(format: "%02d", streamingConversationIndex))",
            markdown: document.source,
            document: document
        )
        reloadItem(at: IndexPath(item: index, section: 0))
        scrollToBottom()
    }
}
