import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private var coordinator: RuntimeCoordinator?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)
    
    // Show splash screen first
    let splashViewController = SplashViewController { [weak self] in
      self?.showMainApp()
    }
    window.rootViewController = splashViewController
    window.makeKeyAndVisible()

    self.window = window
  }
  
  private func showMainApp() {
    // Initialize runtime coordinator and connect in emulated mode by default
    let coordinator = RuntimeCoordinator()
    coordinator.connect(mode: .fixture)
    self.coordinator = coordinator
    
    let rootViewController = DrawerContainerViewController(coordinator: coordinator)
    
    // Transition to main app
    UIView.transition(
      with: window!,
      duration: 0.3,
      options: .transitionCrossDissolve,
      animations: {
        self.window?.rootViewController = rootViewController
      },
      completion: nil
    )
  }
}
