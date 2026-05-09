import UIKit
import MMMDParserCmark
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
        window.rootViewController = DemoMarkdownViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}

final class DemoMarkdownViewController: UIViewController {
    private let markdownView = MarkdownView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MMMDKit iOS Demo"
        view.backgroundColor = .systemBackground

        markdownView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(markdownView)
        NSLayoutConstraint.activate([
            markdownView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            markdownView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            markdownView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            markdownView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        let parser = CmarkMarkdownParser()
        let source = """
        # MMMDKit iOS 示例

        这个示例使用 UIKit 原生入口渲染 Markdown。

        ```swift
        let parser = CmarkMarkdownParser()
        ```
        """
        let document = (try? parser.parse(source, options: .init())) ?? .init(blocks: [])
        markdownView.render(document)
    }
}
