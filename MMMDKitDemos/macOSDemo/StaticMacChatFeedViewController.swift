final class StaticMacChatFeedViewController: MacChatFeedViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        messages = DemoMarkdownSamples.chatMessages
        reloadTranscript()
    }
}
