import UIKit
import Combine
import FinClipChatKit
import ConvoUI

final class ChatViewController: UIViewController {
  private let sessionId: UUID
  private var record: ConversationRecord
  private let coordinator: RuntimeCoordinator
  private var conversation: NeuronKit.Conversation
  private var adapter: ChatKitAdapter?
  private var cancellables = Set<AnyCancellable>()
  private var hasShownWelcome = false
  private var contextProviders: [FinConvoComposerContextProvider] = [] {
    didSet {
      let enabled = !contextProviders.isEmpty
      chatView.inputView.contextProviders = enabled ? contextProviders : nil
      chatView.inputView.contextPickerEnabled = enabled
    }
  }

  private lazy var hosting = ChatHostingController()
  
  private var chatView: FinConvoChatView {
    hosting.chatView
  }

  private func configureComposer() {
    if #available(iOS 15.0, *) {
      let providers = ChatContextProviderFactory.makeDefaultProviders()
      contextProviders = providers
      chatView.inputView.contextPickerEnableMore = false
      chatView.inputView.contextPickerMaxItems = 3
    } else {
      contextProviders = []
    }
  }

  private lazy var statusBanner: UIView = {
    let view = UIView()
    view.backgroundColor = .systemBlue
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  private lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 12, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  private var statusBannerHeightConstraint: NSLayoutConstraint!

  init(record: ConversationRecord, conversation: NeuronKit.Conversation, coordinator: RuntimeCoordinator) {
    self.sessionId = record.sessionId
    self.record = record
    self.conversation = conversation
    self.coordinator = coordinator
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    configureComposer()
    setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    bindAdapterIfNeeded()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    conversation.unbindUI()
    adapter = nil
  }

  private func setupUI() {
    title = record.title
    
    // Embed ChatHostingController with status banner as header
    addChild(hosting)
    view.addSubview(hosting.view)
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    hosting.didMove(toParent: self)
    
    NSLayoutConstraint.activate([
      hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
      hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    
    // Setup status banner as header
    setupStatusBannerHeader()
  }
  
  private func setupStatusBannerHeader() {
    statusBanner.addSubview(statusLabel)
    statusBannerHeightConstraint = statusBanner.heightAnchor.constraint(equalToConstant: 30)
    statusBannerHeightConstraint.isActive = true
    
    NSLayoutConstraint.activate([
      statusLabel.centerXAnchor.constraint(equalTo: statusBanner.centerXAnchor),
      statusLabel.centerYAnchor.constraint(equalTo: statusBanner.centerYAnchor)
    ])
    
    hosting.headerView = statusBanner
  }

  private func setupBindings() {
    coordinator.statePublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        self?.updateStatus(state)
      }
      .store(in: &cancellables)

    coordinator.errorPublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        self?.showError(error)
      }
      .store(in: &cancellables)

    coordinator.recordsPublisher()
      .compactMap { [weak self] records -> ConversationRecord? in
        guard let self else { return nil }
        return records.first(where: { $0.sessionId == self.sessionId })
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] updatedRecord in
        self?.record = updatedRecord
        self?.title = updatedRecord.title
      }
      .store(in: &cancellables)
  }

  private func bindAdapterIfNeeded() {
    guard adapter == nil else { return }
    let adapter = ChatKitAdapter(chatView: chatView)
    self.adapter = adapter
    conversation.bindUI(adapter)

    guard !hasShownWelcome else { return }
    hasShownWelcome = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self else { return }
      if let welcome = FinConvoEvent.systemMessage(withText: "Connected! Send a message to start chatting.") {
        self.chatView.display(welcome)
      }
    }
  }

  private func updateStatus(_ status: String) {
    statusLabel.text = status

    switch status {
    case "Connected":
      applyVisibleStatusBanner(color: .systemGreen)
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
        guard let self else { return }
        self.statusBanner.isHidden = true
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
      }
    case "Connecting...", "Reconnecting...":
      applyVisibleStatusBanner(color: .systemOrange)
    case "Disconnected":
      applyVisibleStatusBanner(color: .systemRed)
    default:
      statusBanner.isHidden = true
      UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }
  }

  private func applyVisibleStatusBanner(color: UIColor) {
    statusBanner.backgroundColor = color
    statusBanner.isHidden = false
    UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
  }


  private func showError(_ error: String) {
    let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }

  deinit {
    conversation.unbindUI()
  }

  var sessionIdentifier: UUID {
    sessionId
  }
}
