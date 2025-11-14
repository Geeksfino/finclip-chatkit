import UIKit
import Combine
import FinClipChatKit

/// Root container managing the drawer and main chat panel
final class DrawerContainerViewController: UIViewController {
  private let coordinator: ChatKitCoordinator
  private var cancellables = Set<AnyCancellable>()
  
  // Drawer
  private lazy var drawerViewController: DrawerViewController = {
    let vc = DrawerViewController(coordinator: coordinator)
    vc.drawerDelegate = self
    return vc
  }()
  
  // Main panel
  private lazy var mainViewController: MainChatViewController = {
    let vc = MainChatViewController(coordinator: coordinator)
    return vc
  }()
  
  private let drawerGap: CGFloat = 80
  private var drawerLeadingConstraint: NSLayoutConstraint!
  private var drawerWidthConstraint: NSLayoutConstraint!
  private var isDrawerOpen = false
  
  private lazy var overlayView: UIView = {
    let overlay = UIView()
    overlay.translatesAutoresizingMaskIntoConstraints = false
    overlay.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    overlay.alpha = 0
    overlay.isHidden = true
    overlay.isUserInteractionEnabled = false
    let tap = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
    overlay.addGestureRecognizer(tap)
    return overlay
  }()
  
  init(coordinator: ChatKitCoordinator) {
    self.coordinator = coordinator
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  private func setupUI() {
    view.backgroundColor = .systemBackground
    
    // Add main view
    addChild(mainViewController)
    view.addSubview(mainViewController.view)
    mainViewController.view.translatesAutoresizingMaskIntoConstraints = false
    mainViewController.didMove(toParent: self)
    
    view.addSubview(overlayView)
    
    // Add drawer
    addChild(drawerViewController)
    view.addSubview(drawerViewController.view)
    drawerViewController.view.translatesAutoresizingMaskIntoConstraints = false
    drawerViewController.didMove(toParent: self)
    
    // Layout constraints
    let initialWidth = UIScreen.main.bounds.width - drawerGap
    drawerLeadingConstraint = drawerViewController.view.leadingAnchor.constraint(
      equalTo: view.leadingAnchor,
      constant: -initialWidth
    )
    drawerWidthConstraint = drawerViewController.view.widthAnchor.constraint(
      equalTo: view.widthAnchor,
      constant: -drawerGap
    )
    
    NSLayoutConstraint.activate([
      // Main view fills screen
      mainViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
      mainViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      mainViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      mainViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      
      overlayView.topAnchor.constraint(equalTo: view.topAnchor),
      overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      
      // Drawer
      drawerLeadingConstraint,
      drawerWidthConstraint,
      drawerViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
      drawerViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
  
  func toggleDrawer() {
    setDrawer(open: !isDrawerOpen)
  }
  
  private func setDrawer(open: Bool) {
    guard open != isDrawerOpen else { return }
    isDrawerOpen = open
    if open {
      overlayView.isHidden = false
      overlayView.isUserInteractionEnabled = true
    }
    drawerLeadingConstraint.constant = open ? 0 : -currentDrawerWidth()
    
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
      self.view.layoutIfNeeded()
      self.mainViewController.view.alpha = open ? 0.3 : 1.0
      self.overlayView.alpha = open ? 1.0 : 0.0
    }, completion: { _ in
      if !open {
        self.overlayView.isHidden = true
        self.overlayView.isUserInteractionEnabled = false
      }
    })
  }
  
  @objc private func overlayTapped() {
    setDrawer(open: false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    drawerLeadingConstraint.constant = isDrawerOpen ? 0 : -currentDrawerWidth()
  }

  private func currentDrawerWidth() -> CGFloat {
    max(0, view.bounds.width - drawerGap)
  }
}

extension DrawerContainerViewController: DrawerViewControllerDelegate {
  func drawerDidRequestToggle() {
    toggleDrawer()
  }
  
  func drawerDidSelectConversation(sessionId: UUID) {
    toggleDrawer()
    mainViewController.switchToConversation(sessionId: sessionId)
  }
  
  func drawerDidRequestNewConversation() {
    toggleDrawer()
    mainViewController.createNewConversation()
  }
}
