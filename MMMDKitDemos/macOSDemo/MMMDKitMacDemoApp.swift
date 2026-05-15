import AppKit
import MMMDCore
import MMMDHighlighter
import MMMDParserCmark
import MMMDStreaming
import MMMDAppKit

@main
enum MMMDKitMacDemoMain {
    private static let appDelegate = AppDelegate()

    static func main() {
        let application = NSApplication.shared
        application.delegate = appDelegate
        application.setActivationPolicy(.regular)
        application.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        installMainMenu()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.showMainWindow()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    private func showMainWindow() {
        let window = window ?? makeMainWindow()
        self.window = window
        NSApp.unhide(nil)
        window.deminiaturize(nil)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        NSLog("MMMDKit macOS Demo 主窗口已显示")
    }

    private func makeMainWindow() -> NSWindow {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let size = NSSize(width: 900, height: 680)
        let origin = NSPoint(x: screenFrame.midX - size.width / 2, y: screenFrame.midY - size.height / 2)
        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 640, height: 480)
        window.title = "MMMDKit macOS Demo"
        window.contentViewController = DemoMarkdownViewController()
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenPrimary]
        return window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "退出 MMMDKitMacDemo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }
}

final class DemoMarkdownViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private let transcriptScrollView = NSScrollView()
    private let transcriptCollectionView = NSCollectionView()
    private let transcriptLayout = NSCollectionViewFlowLayout()
    private let modeControl = NSSegmentedControl(labels: ["30+ 数据", "流式输出"], trackingMode: .selectOne, target: nil, action: nil)
    private let addConversationButton = NSButton(title: "新增对话", target: nil, action: nil)
    private var configuration: MarkdownConfiguration!
    private var messages: [DemoChatMessage] = []
    private var streamingProcessor: StreamingMarkdownProcessor?
    private var streamingTimer: Timer?
    private var streamingChunks: [String] = []
    private var streamingIndex = 0
    private var streamingConversationIndex = 0
    private var currentStreamingAssistantID: String?

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("MMMDKit macOS Demo 内容视图已加载")

        modeControl.selectedSegment = 0
        modeControl.target = self
        modeControl.action = #selector(modeChanged)
        modeControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modeControl)

        addConversationButton.target = self
        addConversationButton.action = #selector(addConversationTapped)
        addConversationButton.bezelStyle = .rounded
        addConversationButton.isHidden = true
        addConversationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addConversationButton)

        setupTranscriptCollectionView()
        NSLayoutConstraint.activate([
            transcriptScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            transcriptScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            modeControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            modeControl.trailingAnchor.constraint(equalTo: addConversationButton.leadingAnchor, constant: -8),
            modeControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            addConversationButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            addConversationButton.centerYAnchor.constraint(equalTo: modeControl.centerYAnchor),
            transcriptScrollView.topAnchor.constraint(equalTo: modeControl.bottomAnchor, constant: 16),
            transcriptScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24)
        ])

        configuration = MarkdownConfiguration(
            actions: .init(
                onLinkTap: { url in
                    NSWorkspace.shared.open(url)
                },
                onCopyCode: { _, _ in
                    NSLog("已复制代码块")
                }
            ),
            codeHighlighter: KeywordCodeHighlighter(),
            codeBlockMaximumWidth: 640
        )
        showChatFeed()
    }

    deinit {
        streamingTimer?.invalidate()
    }

    @objc private func modeChanged() {
        if modeControl.selectedSegment == 0 {
            showChatFeed()
        } else {
            startStreaming(resetTranscript: true)
        }
    }

    @objc private func addConversationTapped() {
        appendStreamingConversation()
    }

    private func setupTranscriptCollectionView() {
        transcriptLayout.minimumInteritemSpacing = 0
        transcriptLayout.minimumLineSpacing = 14
        transcriptLayout.sectionInset = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        transcriptCollectionView.collectionViewLayout = transcriptLayout
        transcriptCollectionView.dataSource = self
        transcriptCollectionView.delegate = self
        transcriptCollectionView.register(ChatMessageItem.self, forItemWithIdentifier: ChatMessageItem.identifier)
        transcriptCollectionView.backgroundColors = [.clear]
        transcriptCollectionView.translatesAutoresizingMaskIntoConstraints = false

        transcriptScrollView.hasVerticalScroller = true
        transcriptScrollView.hasHorizontalScroller = false
        transcriptScrollView.drawsBackground = false
        transcriptScrollView.translatesAutoresizingMaskIntoConstraints = false
        transcriptScrollView.documentView = transcriptCollectionView
        view.addSubview(transcriptScrollView)

        NSLayoutConstraint.activate([
            transcriptCollectionView.leadingAnchor.constraint(equalTo: transcriptScrollView.contentView.leadingAnchor),
            transcriptCollectionView.trailingAnchor.constraint(equalTo: transcriptScrollView.contentView.trailingAnchor),
            transcriptCollectionView.topAnchor.constraint(equalTo: transcriptScrollView.contentView.topAnchor),
            transcriptCollectionView.widthAnchor.constraint(equalTo: transcriptScrollView.contentView.widthAnchor)
        ])
    }

    private func showChatFeed() {
        streamingTimer?.invalidate()
        streamingTimer = nil
        streamingProcessor = nil
        streamingConversationIndex = 0
        currentStreamingAssistantID = nil
        addConversationButton.isHidden = true
        messages = DemoMarkdownSamples.chatMessages
        transcriptLayout.invalidateLayout()
        transcriptCollectionView.reloadData()
    }

    private func startStreaming(resetTranscript: Bool) {
        streamingTimer?.invalidate()
        addConversationButton.isHidden = false
        if resetTranscript {
            streamingConversationIndex = 0
            currentStreamingAssistantID = nil
            messages.removeAll()
            transcriptLayout.invalidateLayout()
            transcriptCollectionView.reloadData()
        }
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
        transcriptCollectionView.animator().insertItems(at: insertedIndexPaths)
        scrollToBottom()

        streamingChunks = DemoMarkdownSamples.streamingChunks()
        streamingIndex = 0
        let processor = StreamingMarkdownProcessor(parser: CmarkMarkdownParser())
        processor.onDiff = { [weak self] diff in
            DispatchQueue.main.async {
                guard let self else { return }
                self.replaceStreamingAssistant(with: diff.document)
            }
        }
        streamingProcessor = processor
        processor.reset()

        streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.045, repeats: true) { [weak self] timer in
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
        let indexPath = IndexPath(item: index, section: 0)
        transcriptLayout.invalidateLayout()
        transcriptCollectionView.reloadItems(at: Set([indexPath]))
        scrollToBottom()
    }

    private func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.messages.isEmpty else { return }
            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
            self.transcriptCollectionView.scrollToItems(at: Set([indexPath]), scrollPosition: .bottom)
        }
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ChatMessageItem.identifier, for: indexPath) as? ChatMessageItem ?? ChatMessageItem()
        item.configure(message: messages[indexPath.item], configuration: configuration)
        return item
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        let width = max(1, collectionView.enclosingScrollView?.contentView.bounds.width ?? collectionView.bounds.width)
        let height = ChatMessageRowView.estimatedHeight(for: messages[indexPath.item], width: width, configuration: configuration)
        return NSSize(width: width, height: height)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        transcriptLayout.invalidateLayout()
    }
}

private final class ChatMessageItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("MMMDKit.ChatMessageItem")

    override func loadView() {
        view = ChatMessageRowView()
    }

    func configure(message: DemoChatMessage, configuration: MarkdownConfiguration) {
        (view as? ChatMessageRowView)?.configure(message: message, configuration: configuration)
    }
}

private final class ChatMessageRowView: NSView {
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

    static func estimatedHeight(for message: DemoChatMessage, width: CGFloat, configuration: MarkdownConfiguration) -> CGFloat {
        let bubbleWidth = max(1, width * 0.82 - 28)
        let markdownHeight = MarkdownNSView.estimatedHeight(for: message.document, width: bubbleWidth, configuration: configuration)
        return max(44, ceil(10 + 14 + 8 + markdownHeight + 12))
    }
}
