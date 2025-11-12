import UIKit
import Combine
import FinClipChatKit

final class ConnectionViewController: UIViewController {
  private var coordinator: ChatKitCoordinator?
  private var cancellables = Set<AnyCancellable>()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Simple"
    label.font = .systemFont(ofSize: 28, weight: .bold)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  private lazy var serverHintLabel: UILabel = {
    let label = UILabel()
    label.text = "Connecting to: http://127.0.0.1:3000/agent"
    label.font = .systemFont(ofSize: 14)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var connectButton: UIButton = {
    var config = UIButton.Configuration.filled()
    config.title = "Connect"
    config.cornerStyle = .medium
    let button = UIButton(configuration: config)
    button.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.text = "Ready to connect"
    label.font = .systemFont(ofSize: 14)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupCoordinator()
  }

  private func setupUI() {
    view.backgroundColor = .systemBackground
    title = "Connect"

    view.addSubview(titleLabel)
    view.addSubview(serverHintLabel)
    view.addSubview(connectButton)
    view.addSubview(statusLabel)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      serverHintLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
      serverHintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
      serverHintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

      connectButton.topAnchor.constraint(equalTo: serverHintLabel.bottomAnchor, constant: 30),
      connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      connectButton.widthAnchor.constraint(equalToConstant: 200),
      connectButton.heightAnchor.constraint(equalToConstant: 50),

      statusLabel.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
      statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
    ])
  }

  private func setupCoordinator() {
    // Coordinator will be created when user connects
    // Network state monitoring will be set up after coordinator is created
  }

  @objc private func connectTapped() {
    connectButton.isEnabled = false
    statusLabel.text = "Connecting..."

    // Create coordinator
    let config = NeuronKitConfig.default(serverURL: AppConfig.defaultServerURL)
        .withUserId(AppConfig.defaultUserId)
    let coordinator = ChatKitCoordinator(config: config)
    self.coordinator = coordinator
    
    // Monitor network state
    coordinator.runtime.networkStatePublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        guard let self = self else { return }
        switch state {
        case .connected:
          self.statusLabel.text = "Connected"
        case .connecting:
          self.statusLabel.text = "Connecting..."
        case .reconnecting:
          self.statusLabel.text = "Reconnecting..."
        case .disconnected:
          self.statusLabel.text = "Disconnected"
        case .error(let error):
          self.statusLabel.text = "Error"
          self.showAlert("Connection Error", message: error.message)
        @unknown default:
          self.statusLabel.text = "Unknown state"
        }
      }
      .store(in: &cancellables)

    let listVC = ConversationListViewController(coordinator: coordinator)
    listVC.autoCreateConversation = true
    navigationController?.pushViewController(listVC, animated: true)

    connectButton.isEnabled = true
  }

  private func showAlert(_ title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}
