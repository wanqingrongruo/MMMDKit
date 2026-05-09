import AppKit
import MMMDCore
import MMMDHighlighter
import MMMDParserCmark
import MMMDStreaming
import MMMDAppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let viewController = DemoMarkdownViewController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "MMMDKit macOS Demo"
        window.contentViewController = viewController
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

final class DemoMarkdownViewController: NSViewController {
    private let markdownView = MarkdownCollectionViewHost()
    private let modeControl = NSSegmentedControl(labels: ["30+ 数据", "流式输出"], trackingMode: .selectOne, target: nil, action: nil)
    private var configuration: MarkdownConfiguration!
    private var streamingProcessor: StreamingMarkdownProcessor?
    private var streamingTimer: Timer?
    private var streamingChunks: [String] = []
    private var streamingIndex = 0

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        modeControl.selectedSegment = 0
        modeControl.target = self
        modeControl.action = #selector(modeChanged)
        modeControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modeControl)

        markdownView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(markdownView)
        NSLayoutConstraint.activate([
            markdownView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            markdownView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            modeControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            modeControl.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            modeControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            markdownView.topAnchor.constraint(equalTo: modeControl.bottomAnchor, constant: 16),
            markdownView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24)
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
            codeHighlighter: KeywordCodeHighlighter()
        )
        showLongFeed()
    }

    deinit {
        streamingTimer?.invalidate()
    }

    @objc private func modeChanged() {
        if modeControl.selectedSegment == 0 {
            showLongFeed()
        } else {
            startStreaming()
        }
    }

    private func showLongFeed() {
        streamingTimer?.invalidate()
        streamingTimer = nil
        streamingProcessor = nil
        markdownView.render(DemoMarkdownSamples.makeLongFeedDocument(), configuration: configuration)
    }

    private func startStreaming() {
        streamingTimer?.invalidate()
        streamingChunks = DemoMarkdownSamples.streamingChunks()
        streamingIndex = 0

        let processor = StreamingMarkdownProcessor(parser: CmarkMarkdownParser())
        processor.onDiff = { [weak self] diff in
            DispatchQueue.main.async {
                guard let self else { return }
                self.markdownView.render(diff.document, configuration: self.configuration)
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
}
