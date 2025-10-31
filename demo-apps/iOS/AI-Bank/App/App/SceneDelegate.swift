import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)
    
    // Initialize runtime coordinator and connect in emulated mode by default
    let coordinator = RuntimeCoordinator()
    coordinator.connect(mode: .fixture)
    
    let rootViewController = DrawerContainerViewController(coordinator: coordinator)
    window.rootViewController = rootViewController
    window.makeKeyAndVisible()

    self.window = window
  }
}
