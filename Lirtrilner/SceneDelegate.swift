import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let scene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: scene)
    let home = LirtrilnerWorkshopViewController()
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-LirtrilnerRenderAudit") {
        home.firstAppearance = false
      }
    #endif
    let navigation = UINavigationController(rootViewController: home)
    navigation.navigationBar.tintColor = WorkshopStyle.ink
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = WorkshopStyle.cream
    appearance.shadowColor = .clear
    appearance.titleTextAttributes = [.foregroundColor: WorkshopStyle.ink]
    navigation.navigationBar.standardAppearance = appearance
    navigation.navigationBar.scrollEdgeAppearance = appearance
    window.rootViewController = navigation
    window.overrideUserInterfaceStyle = .light
    window.makeKeyAndVisible()
    self.window = window
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-LirtrilnerRenderAudit") {
        DispatchQueue.main.async { LirtrilnerRenderAudit.run(window: window) }
      }
    #endif
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    let context = LirtrilnerContext.shared
    context.persist()
    context.store.flush()
  }
}
