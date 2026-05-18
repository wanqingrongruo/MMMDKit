import UIKit

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

final class DemoMarkdownViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MMMDKit iOS Demo"
        view.backgroundColor = .systemBackground

        let staticController = StaticChatFeedViewController()
        staticController.tabBarItem = UITabBarItem(title: "30+ 数据", image: UIImage(systemName: "text.alignleft"), selectedImage: nil)

        let streamingController = StreamingChatFeedViewController()
        streamingController.tabBarItem = UITabBarItem(title: "流式输出", image: UIImage(systemName: "dot.radiowaves.left.and.right"), selectedImage: nil)

        viewControllers = [
            UINavigationController(rootViewController: staticController),
            UINavigationController(rootViewController: streamingController)
        ]
    }
}
