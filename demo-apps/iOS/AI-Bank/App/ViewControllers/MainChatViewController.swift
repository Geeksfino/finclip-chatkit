import UIKit
import Combine
import FinClipChatKit

final class MainChatViewController: UIViewController {
  private let coordinator: RuntimeCoordinator
  private var currentChatVC: ChatViewController?
  private var cancellables = Set<AnyCancellable>()
  
  // Top bar
  private lazy var topBarView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .systemBackground
    return view
  }()
  
  private lazy var hamburgerButton: UIButton = {
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
    let image = UIImage(systemName: "line.3.horizontal", withConfiguration: config)
    let button = UIButton(type: .system)
    button.setImage(image, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(hamburgerTapped), for: .touchUpInside)
    return button
  }()
  
  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Select Channel"
    label.font = .systemFont(ofSize: 18, weight: .semibold)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  private lazy var addButton: UIButton = {
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
    let image = UIImage(systemName: "plus", withConfiguration: config)
    let button = UIButton(type: .system)
    button.setImage(image, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    return button
  }()
  
  
  // Chat container
  private lazy var chatContainerView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .systemBackground
    return view
  }()
  
  
  // Empty state
  private lazy var emptyStateView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .systemBackground
    
    let label = UILabel()
    label.text = "Hello! 👋\nTap + in the top right to select an agent\nand start a new conversation"
    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 20, weight: .medium)
    label.textColor = .secondaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
    ])
    
    return view
  }()
  
  init(coordinator: RuntimeCoordinator) {
    self.coordinator = coordinator
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    observeActiveAgent()
    showEmptyState()
  }
  
  private func observeActiveAgent() {
    coordinator.activeAgentPublisher()
      .sink { [weak self] agent in
        self?.updateTitle(for: agent)
      }
      .store(in: &cancellables)
  }
  
  private func updateTitle(for agent: AgentProfile?) {
    if let agent = agent {
      titleLabel.text = agent.name
    } else {
      titleLabel.text = "Select Channel"
    }
  }
  
  private func setupUI() {
    view.backgroundColor = .systemBackground
    
    // Top bar setup
    topBarView.addSubview(hamburgerButton)
    topBarView.addSubview(titleLabel)
    topBarView.addSubview(addButton)
    
    view.addSubview(topBarView)
    view.addSubview(chatContainerView)
    
    NSLayoutConstraint.activate([
      // Top bar
      topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topBarView.heightAnchor.constraint(equalToConstant: 60),
      
      hamburgerButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16),
      hamburgerButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
      
      titleLabel.centerXAnchor.constraint(equalTo: topBarView.centerXAnchor),
      titleLabel.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
      
      addButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor, constant: -16),
      addButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
      
      // Chat container
      chatContainerView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
      chatContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      chatContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      chatContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
  
  private func showEmptyState() {
    chatContainerView.subviews.forEach { $0.removeFromSuperview() }
    chatContainerView.addSubview(emptyStateView)
    
    NSLayoutConstraint.activate([
      emptyStateView.topAnchor.constraint(equalTo: chatContainerView.topAnchor),
      emptyStateView.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor),
      emptyStateView.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor),
      emptyStateView.bottomAnchor.constraint(equalTo: chatContainerView.bottomAnchor)
    ])
  }
  
  func switchToConversation(sessionId: UUID) {
    guard let conversation = coordinator.conversation(for: sessionId),
          let record = coordinator.record(for: sessionId) else {
      print("[MainChatViewController] Failed to load conversation \(sessionId)")
      return
    }
    if currentChatVC?.sessionIdentifier == sessionId {
      return
    }
    
    embedChatViewController(record: record, conversation: conversation)
  }
  
  func createNewConversation() {
    guard let (record, conversation) = coordinator.startConversation() else {
      print("[MainChatViewController] Failed to create conversation")
      return
    }
    
    embedChatViewController(record: record, conversation: conversation)
  }
  
  private func embedChatViewController(record: ConversationRecord, conversation: NeuronKit.Conversation) {
    // Remove existing chat
    if let existing = currentChatVC {
      existing.willMove(toParent: nil)
      existing.beginAppearanceTransition(false, animated: false)
      existing.view.removeFromSuperview()
      existing.endAppearanceTransition()
      existing.removeFromParent()
    }
    
    // Add new chat
    let chatVC = ChatViewController(record: record, conversation: conversation, coordinator: coordinator)
    addChild(chatVC)
    chatVC.beginAppearanceTransition(true, animated: false)
    chatContainerView.addSubview(chatVC.view)
    chatVC.view.translatesAutoresizingMaskIntoConstraints = false
    chatVC.didMove(toParent: self)
    
    NSLayoutConstraint.activate([
      chatVC.view.topAnchor.constraint(equalTo: chatContainerView.topAnchor),
      chatVC.view.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor),
      chatVC.view.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor),
      chatVC.view.bottomAnchor.constraint(equalTo: chatContainerView.bottomAnchor)
    ])
    chatVC.endAppearanceTransition()
    
    currentChatVC = chatVC
    emptyStateView.removeFromSuperview()
  }
  
  @objc private func hamburgerTapped() {
    if let container = parent as? DrawerContainerViewController {
      container.toggleDrawer()
    }
  }
  
  @objc private func addButtonTapped() {
    let alert = UIAlertController(title: "Select Channel", message: "Choose a channel to start a new conversation", preferredStyle: .actionSheet)
    
    // Only show the two channels (Parrot Echo and Personal Banking)
    let allAgents = StaticAgentCatalog.defaultAgents
    let channels = allAgents.filter { $0.name == "Parrot Echo" || $0.name == "Personal Banking" }
    
    for agent in channels {
      alert.addAction(UIAlertAction(title: agent.name, style: .default) { [weak self] _ in
        self?.startConversationWithAgent(agent)
      })
    }
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    if let popover = alert.popoverPresentationController {
      popover.sourceView = addButton
      popover.sourceRect = addButton.bounds
    }
    
    present(alert, animated: true)
  }
  
  private func startConversationWithAgent(_ agent: AgentProfile) {
    // Switch to the selected agent and connection mode
    coordinator.reconnect(mode: agent.connectionMode)
    coordinator.setActiveAgent(agent)
    
    // Create a new conversation with this agent
    guard let (record, conversation) = coordinator.startConversation() else {
      print("[MainChatViewController] Failed to create conversation with agent \(agent.name)")
      return
    }
    
    embedChatViewController(record: record, conversation: conversation)
  }
}
