import AppKit
import MMMDParserCmark
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
    private let markdownView = MarkdownNSView()

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        markdownView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(markdownView)
        NSLayoutConstraint.activate([
            markdownView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            markdownView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            markdownView.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            markdownView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24)
        ])

        let parser = CmarkMarkdownParser()
        let source = """
        # MMMDKit macOS 示例

        这个示例使用 AppKit 原生入口渲染 Markdown。

        ```swift
        let parser = CmarkMarkdownParser()
        ```
        """
        let document = (try? parser.parse(source, options: .init())) ?? .init(blocks: [])
        markdownView.render(document)
    }
}
