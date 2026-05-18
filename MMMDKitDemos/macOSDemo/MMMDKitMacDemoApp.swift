import AppKit

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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
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

final class DemoMarkdownViewController: NSTabViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("MMMDKit macOS Demo 内容视图已加载")

        let staticController = StaticMacChatFeedViewController()
        staticController.title = "30+ 数据"

        let streamingController = StreamingMacChatFeedViewController()
        streamingController.title = "流式输出"

        addChild(staticController)
        addChild(streamingController)
    }
}
