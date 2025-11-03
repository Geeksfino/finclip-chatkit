import UIKit
import Combine
import FinClipChatKit

final class ConversationListViewController: UIViewController {
  private let coordinator: RuntimeCoordinator
  private var records: [ConversationRecord] = []
  private var cancellables = Set<AnyCancellable>()

  var autoCreateConversation = false

  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.tableFooterView = UIView()
    tableView.backgroundColor = .systemBackground
    tableView.rowHeight = 72
    return tableView
  }()

  private lazy var emptyLabel: UILabel = {
    let label = UILabel()
    label.text = "No conversations yet. Tap \"New Conversation\" to get started."
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isHidden = true
    return label
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
    bindRecords()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if autoCreateConversation {
      autoCreateConversation = false
      if records.isEmpty {
        createConversation(openImmediately: true)
      }
    }
  }

  private func setupUI() {
    title = "Conversations"
    view.backgroundColor = .systemBackground

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "+",
      style: .plain,
      target: self,
      action: #selector(newConversationTapped)
    )

    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Disconnect",
      style: .plain,
      target: self,
      action: #selector(disconnectTapped)
    )

    view.addSubview(tableView)
    view.addSubview(emptyLabel)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
    ])
  }

  private func bindRecords() {
    coordinator.recordsPublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] records in
        self?.records = records
        self?.tableView.reloadData()
        self?.emptyLabel.isHidden = !records.isEmpty
      }
      .store(in: &cancellables)

    records = coordinator.recordsSnapshot()
    emptyLabel.isHidden = !records.isEmpty
  }

  @objc private func newConversationTapped() {
    createConversation(openImmediately: true)
  }

  private func createConversation(openImmediately: Bool) {
    guard let (record, conversation) = coordinator.startConversation() else {
      showAlert(title: "Unable to Create Conversation", message: "Please try again.")
      return
    }

    if openImmediately {
      openConversation(record: record, conversation: conversation)
    }
  }

  private func openConversation(record: ConversationRecord, conversation: NeuronKit.Conversation) {
    let chat = ChatViewController(record: record, conversation: conversation, coordinator: coordinator)
    navigationController?.pushViewController(chat, animated: true)
  }

  private func openConversation(for record: ConversationRecord) {
    guard let conversation = coordinator.conversation(for: record.sessionId) else {
      showAlert(title: "Conversation Unavailable", message: "The conversation could not be loaded.")
      return
    }

    openConversation(record: record, conversation: conversation)
  }

  @objc private func disconnectTapped() {
    coordinator.disconnect()
    navigationController?.popToRootViewController(animated: true)
  }

  private func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

extension ConversationListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    records.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let identifier = "ConversationCell"
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

    let record = records[indexPath.row]
    cell.textLabel?.text = record.title

    var detail = record.lastMessagePreview ?? "No messages yet"
    detail += " • " + record.lastUpdatedDescription
    cell.detailTextLabel?.text = detail

    cell.accessoryType = .disclosureIndicator
    cell.detailTextLabel?.textColor = .secondaryLabel

    return cell
  }
}

extension ConversationListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let record = records[indexPath.row]
    openConversation(for: record)
  }

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let record = records[indexPath.row]

    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
      self?.coordinator.removeConversation(sessionId: record.sessionId)
      completion(true)
    }

    deleteAction.backgroundColor = .systemRed
    return UISwipeActionsConfiguration(actions: [deleteAction])
  }
}
