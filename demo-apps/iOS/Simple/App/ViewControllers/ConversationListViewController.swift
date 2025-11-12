import UIKit
import Combine
import FinClipChatKit

final class ConversationListViewController: UIViewController {
  private let coordinator: ChatKitCoordinator
  private var records: [FinClipChatKit.ConversationRecord] = []
  private var cancellables = Set<AnyCancellable>()
  private var searchText: String = ""

  var autoCreateConversation = false

  private lazy var searchController: UISearchController = {
    let controller = UISearchController(searchResultsController: nil)
    controller.searchResultsUpdater = self
    controller.obscuresBackgroundDuringPresentation = false
    controller.searchBar.placeholder = "Search conversations..."
    return controller
  }()

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

    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false

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
    // Use search publisher when search text is provided, otherwise use regular publisher
    let searchTextSubject = CurrentValueSubject<String, Never>("")
    
    searchTextSubject
      .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
      .flatMap { [weak self] searchText -> AnyPublisher<[FinClipChatKit.ConversationRecord], Never> in
        guard let self = self else {
          return Just([]).eraseToAnyPublisher()
        }
        self.searchText = searchText
        if searchText.isEmpty {
          return self.coordinator.recordsPublisher
        } else {
          return self.coordinator.searchPublisher(searchText)
        }
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] records in
        self?.records = records
        self?.tableView.reloadData()
        self?.emptyLabel.isHidden = !records.isEmpty
      }
      .store(in: &cancellables)
    
    // Update search text when search bar changes
    searchController.searchBar.textPublisher
      .map { $0 ?? "" }
      .subscribe(searchTextSubject)
      .store(in: &cancellables)
    
    // Initial load
    records = coordinator.allConversations()
    emptyLabel.isHidden = !records.isEmpty
  }

  @objc private func newConversationTapped() {
    createConversation(openImmediately: true)
  }

  private func createConversation(openImmediately: Bool) {
    Task { @MainActor in
      do {
        let (record, conversation) = try await coordinator.startConversation(
          agentId: AppConfig.defaultAgentId,
          title: nil,
          agentName: AppConfig.defaultAgentName
        )
        if openImmediately {
          openConversation(record: record, conversation: conversation)
        }
      } catch {
        showAlert(title: "Unable to Create Conversation", message: "Failed to persist conversation. Please try again.")
      }
    }
  }

  private func openConversation(record: FinClipChatKit.ConversationRecord, conversation: NeuronKit.Conversation) {
    let chat = ChatViewController(record: record, conversation: conversation, coordinator: coordinator)
    navigationController?.pushViewController(chat, animated: true)
  }

  private func openConversation(for record: FinClipChatKit.ConversationRecord) {
    guard let conversation = coordinator.conversation(for: record.id) else {
      showAlert(title: "Conversation Unavailable", message: "The conversation could not be loaded.")
      return
    }

    openConversation(record: record, conversation: conversation)
  }

  @objc private func disconnectTapped() {
    // Coordinator lifecycle is managed by the app, just navigate back
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
      self?.coordinator.deleteConversation(sessionId: record.id)
      completion(true)
    }
    
    deleteAction.backgroundColor = UIColor.systemRed
    return UISwipeActionsConfiguration(actions: [deleteAction])
  }
}

// MARK: - UISearchResultsUpdating

extension ConversationListViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    // Search is handled by bindRecords() via searchBar.textPublisher
    // This method is required by protocol but we handle updates reactively
  }
}

// MARK: - UISearchBar Text Publisher Extension

extension UISearchBar {
  var textPublisher: AnyPublisher<String?, Never> {
    NotificationCenter.default.publisher(
      for: UITextField.textDidChangeNotification,
      object: self
    )
    .map { notification -> String? in
      guard let searchBar = notification.object as? UISearchBar else { return nil }
      return searchBar.text
    }
    .eraseToAnyPublisher()
  }
}
