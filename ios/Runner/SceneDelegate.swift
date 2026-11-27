import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    private let engine = FlutterEngine(name: "playground.controls")

    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                        options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        engine.run()
        GeneratedPluginRegistrant.register(with: engine)
        registerSceneLifeCycle(with: engine)
        let controls = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        let navigation = UINavigationController(rootViewController: PlaygroundTabs(controls: controls))
        navigation.navigationBar.prefersLargeTitles = true
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }
}
