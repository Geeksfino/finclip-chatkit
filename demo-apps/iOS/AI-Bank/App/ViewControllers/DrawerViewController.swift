import UIKit
import Combine
import FinClipChatKit

protocol DrawerViewControllerDelegate: AnyObject {
  func drawerDidRequestToggle()
  func drawerDidSelectConversation(sessionId: UUID)
  func drawerDidRequestNewConversation()
}

final class DrawerViewController: UIViewController {
  weak var delegate: DrawerViewControllerDelegate?
  private let coordinator: RuntimeCoordinator
  private var records: [ConversationRecord] = []
  private var filteredRecords: [ConversationRecord] = []
  private var cancellables = Set<AnyCancellable>()
  
  private lazy var tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .systemBackground
    tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    tableView.rowHeight = 56
    tableView.keyboardDismissMode = .onDrag
    return tableView
  }()
  
  private lazy var headerView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .systemBackground
    return view
  }()
  
  private lazy var headerStack: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
  }()
  
  private lazy var searchStack: UIStackView = {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 12
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
  }()
  
  private lazy var searchField: UISearchTextField = {
    let field = UISearchTextField(frame: .zero)
    field.placeholder = "Search"
    field.translatesAutoresizingMaskIntoConstraints = false
    field.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
    return field
  }()
  
  private lazy var newButton: UIButton = {
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: "square.and.pencil")
    config.baseForegroundColor = .label
    config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(newConversationTapped), for: .touchUpInside)
    button.widthAnchor.constraint(equalToConstant: 36).isActive = true
    button.heightAnchor.constraint(equalToConstant: 36).isActive = true
    button.backgroundColor = .secondarySystemBackground
    button.layer.cornerRadius = 10
    return button
  }()
  
  private lazy var titleRow: UIStackView = {
    let iconView = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right.fill"))
    iconView.tintColor = .label
    iconView.contentMode = .scaleAspectFit
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
    iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
    
    let label = UILabel()
    label.text = "MyChatGPT"
    label.font = .systemFont(ofSize: 20, weight: .semibold)
    
    let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    chevron.tintColor = .tertiaryLabel
    chevron.translatesAutoresizingMaskIntoConstraints = false
    chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true
    
    let stack = UIStackView(arrangedSubviews: [iconView, label, UIView(), chevron])
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
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
    bindData()
  }
  
  private func setupUI() {
    view.backgroundColor = .systemBackground
    
    view.addSubview(headerView)
    headerView.addSubview(headerStack)
    view.addSubview(tableView)
    
    NSLayoutConstraint.activate([
      headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headerView.bottomAnchor.constraint(equalTo: tableView.topAnchor),

      headerStack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
      headerStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
      headerStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
      headerStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),

      searchStack.heightAnchor.constraint(equalToConstant: 40),

      tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    headerStack.addArrangedSubview(searchStack)
    headerStack.addArrangedSubview(titleRow)

    searchStack.addArrangedSubview(searchField)
    searchStack.addArrangedSubview(newButton)
    searchField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    searchField.layer.cornerRadius = 12
    searchField.backgroundColor = .secondarySystemBackground
  }
  
  private func bindData() {
    coordinator.recordsPublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] records in
        self?.records = records
        self?.applyFilter()
      }
      .store(in: &cancellables)
    records = coordinator.recordsSnapshot()
    applyFilter()
  }
  
  @objc private func newConversationTapped() {
    delegate?.drawerDidRequestNewConversation()
  }

  @objc private func searchTextChanged() {
    applyFilter()
  }

  private func applyFilter() {
    let query = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if query.isEmpty {
      filteredRecords = records
    } else {
      filteredRecords = records.filter { record in
        record.title.localizedCaseInsensitiveContains(query) || (record.lastMessagePreview?.localizedCaseInsensitiveContains(query) ?? false)
      }
    }
    tableView.reloadData()
  }
}

extension DrawerViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filteredRecords.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let identifier = "ConversationCell"
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)

    let record = filteredRecords[indexPath.row]
    var content = UIListContentConfiguration.sidebarCell()
    content.text = record.title
    if let preview = record.lastMessagePreview, !preview.isEmpty {
      content.secondaryText = preview
    }
    cell.contentConfiguration = content
    cell.backgroundColor = .clear
    cell.selectionStyle = .default

    return cell
  }
}

extension DrawerViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let record = filteredRecords[indexPath.row]
    
    delegate?.drawerDidSelectConversation(sessionId: record.sessionId)
  }
  
  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let record = filteredRecords[indexPath.row]
    
    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
      self?.coordinator.removeConversation(sessionId: record.sessionId)
      completion(true)
    }
    
    deleteAction.backgroundColor = .systemRed
    return UISwipeActionsConfiguration(actions: [deleteAction])
  }
}
