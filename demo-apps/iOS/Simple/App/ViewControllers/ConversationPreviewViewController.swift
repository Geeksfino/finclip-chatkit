import UIKit
import FinClipChatKit
import NeuronKit

/// Displays a read-only preview of a conversation's message history.
/// 
/// Used in the drawer to show historical messages when a conversation is selected.
final class ConversationPreviewViewController: HistoricalMessagesViewController {
  
  private weak var headerTitleLabel: UILabel?
  private let previewTitle: String
  
  init(sessionId: UUID, runtime: NeuronRuntime, title: String) {
    self.previewTitle = title
    super.init(sessionId: sessionId, runtime: runtime)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) not supported")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerView = makeHeaderView()
  }
  
  private func makeHeaderView() -> UIView {
    let view = UIView()
    view.backgroundColor = .systemBackground
    view.translatesAutoresizingMaskIntoConstraints = false
    
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    
    let titleLabel = UILabel()
    titleLabel.text = previewTitle
    titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    
    let subtitleLabel = UILabel()
    subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.text = "Read-only message history"
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    
    stack.addArrangedSubview(titleLabel)
    stack.addArrangedSubview(subtitleLabel)
    
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
    ])
    
    self.headerTitleLabel = titleLabel
    return view
  }
}
