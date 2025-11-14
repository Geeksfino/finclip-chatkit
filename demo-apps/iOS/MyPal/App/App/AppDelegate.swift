import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Check device type and warn if on simulator
    if DeviceDetection.isSimulator {
      print("⚠️ [AppDelegate] Running on iOS Simulator")
      print("   MLX requires Metal GPU which is not available on simulator")
      print("   Local LLM mode will be disabled. Please test on a physical device.")
    } else {
      print("✅ [AppDelegate] Running on physical device - MLX GPU available")
    }
    
    return true
  }

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}
