import UIKit

final class StaticChatFeedViewController: ChatFeedViewController {
    private var didLoadMessages = false
    private var isLoadingMessages = false

    init() {
        super.init(title: "30+ 数据")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        title = "30+ 数据"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadMessagesIfNeeded()
    }

    private func loadMessagesIfNeeded() {
        guard !didLoadMessages, !isLoadingMessages, view.bounds.width > 0 else { return }
        isLoadingMessages = true
        let width = view.bounds.width
        let configuration = configuration!

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let models = DemoMarkdownSamples.makeChatMessages().map {
                MessageLayoutModel(
                    message: $0,
                    layout: ChatBubbleLayoutEngine.build(message: $0, configuration: configuration, containerWidth: width)
                )
            }

            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingMessages = false
                self.didLoadMessages = true
                self.messages = models
                self.reloadTranscript()
                self.scrollToBottom(animated: false)
            }
        }
    }
}
