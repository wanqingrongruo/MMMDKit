import AppKit

final class StaticMacChatFeedViewController: MacChatFeedViewController {
    private var didLoadMessages = false

    override func viewDidLayout() {
        super.viewDidLayout()
        loadMessagesIfNeeded()
    }

    private func loadMessagesIfNeeded() {
        guard !didLoadMessages, view.bounds.width > 0 else { return }
        didLoadMessages = true
        messages = DemoMarkdownSamples.chatMessages.map { buildLayoutModel(for: $0) }
        reloadTranscript()
        scrollToBottom()
    }
}
