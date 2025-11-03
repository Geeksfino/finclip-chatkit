import UIKit
import Combine
import FinClipChatKit

final class ConnectionViewController: UIViewController {
  private let coordinator = RuntimeCoordinator()
  private var isFixtureMode = true
  private var cancellables = Set<AnyCancellable>()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.text = "MyChatGPT"
    label.font = .systemFont(ofSize: 28, weight: .bold)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var modeToggle: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Fixture", "Remote"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
    control.translatesAutoresizingMaskIntoConstraints = false
    return control
  }()

  private lazy var urlTextField: UITextField = {
    let field = UITextField()
    field.text = "http://127.0.0.1:3000/agent"
    field.placeholder = "http://127.0.0.1:3000/agent"
    field.borderStyle = .roundedRect
    field.autocapitalizationType = .none
    field.autocorrectionType = .no
    field.keyboardType = .URL
    field.isHidden = true
    field.translatesAutoresizingMaskIntoConstraints = false
    return field
  }()
  
  private lazy var serverHintLabel: UILabel = {
    let label = UILabel()
    label.text = "Default: agui-test-server @ http://127.0.0.1:3000/agent"
    label.font = .systemFont(ofSize: 12)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.numberOfLines = 0
    label.isHidden = true
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
    view.addSubview(modeToggle)
    view.addSubview(urlTextField)
    view.addSubview(serverHintLabel)
    view.addSubview(connectButton)
    view.addSubview(statusLabel)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      modeToggle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
      modeToggle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      modeToggle.widthAnchor.constraint(equalToConstant: 200),

      urlTextField.topAnchor.constraint(equalTo: modeToggle.bottomAnchor, constant: 30),
      urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
      urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
      urlTextField.heightAnchor.constraint(equalToConstant: 44),
      
      serverHintLabel.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 8),
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
    coordinator.statePublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        self?.statusLabel.text = state
      }
      .store(in: &cancellables)

    coordinator.errorPublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        self?.showAlert("Connection Error", message: error)
      }
      .store(in: &cancellables)
  }

  @objc private func modeChanged() {
    isFixtureMode = (modeToggle.selectedSegmentIndex == 0)
    urlTextField.isHidden = isFixtureMode
    serverHintLabel.isHidden = isFixtureMode
  }

  @objc private func connectTapped() {
    let mode: ConnectionMode

    if isFixtureMode {
      mode = .fixture
    } else {
      guard let urlString = urlTextField.text, !urlString.isEmpty, let url = URL(string: urlString) else {
        showAlert("Invalid URL", message: "Please enter a valid server URL")
        return
      }
      mode = .remote(url)
    }

    connectButton.isEnabled = false
    statusLabel.text = "Connecting..."

    coordinator.connect(mode: mode)

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
