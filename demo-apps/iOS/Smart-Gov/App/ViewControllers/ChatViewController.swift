import UIKit
import Combine
import FinClipChatKit

final class ChatViewController: UIViewController {
  private let sessionId: UUID
  private var record: ConversationRecord
  private let coordinator: RuntimeCoordinator
  private var conversation: NeuronKit.Conversation
  private var adapter: ChatKitAdapter?
  private var cancellables = Set<AnyCancellable>()
  private var hasShownWelcome = false

  private lazy var chatView: FinConvoChatView = {
    let view = FinConvoChatView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

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

  private lazy var mainStackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 0
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
  }()

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
    view.backgroundColor = .systemBackground
    title = record.title

    view.addSubview(mainStackView)
    mainStackView.addArrangedSubview(statusBanner)
    mainStackView.addArrangedSubview(chatView)
    statusBanner.addSubview(statusLabel)

    NSLayoutConstraint.activate([
      mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

      statusBanner.heightAnchor.constraint(equalToConstant: 30),
      statusLabel.centerXAnchor.constraint(equalTo: statusBanner.centerXAnchor),
      statusLabel.centerYAnchor.constraint(equalTo: statusBanner.centerYAnchor)
    ])
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
      statusBanner.backgroundColor = .systemGreen
      statusBanner.isHidden = false
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
        self?.statusBanner.isHidden = true
      }
    case "Connecting...", "Reconnecting...":
      statusBanner.backgroundColor = .systemOrange
      statusBanner.isHidden = false
    case "Disconnected":
      statusBanner.backgroundColor = .systemRed
      statusBanner.isHidden = false
    default:
      statusBanner.isHidden = true
    }
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
