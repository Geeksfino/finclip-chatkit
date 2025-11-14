import UIKit
import FinClipChatKit

protocol DrawerViewControllerDelegate: AnyObject {
  func drawerDidRequestToggle()
  func drawerDidSelectConversation(sessionId: UUID)
  func drawerDidRequestNewConversation()
}

/// Simplified DrawerViewController using ChatKitConversationListViewController
///
/// This is now a thin wrapper that configures ChatKitConversationListViewController
/// and adapts its delegate to the drawer-specific delegate pattern.
final class DrawerViewController: ChatKitConversationListViewController {
  weak var drawerDelegate: DrawerViewControllerDelegate?
  
  init(coordinator: ChatKitCoordinator) {
    // Configure with app-specific settings
    var config = ChatKitConversationListConfiguration.default
    config.headerTitle = "Simple"
    config.headerIcon = UIImage(systemName: "bubble.left.and.bubble.right.fill")
    config.searchPlaceholder = "Search"
    config.showHeader = true
    config.showSearchBar = true
    config.showNewButton = true
    config.enableSwipeToDelete = true
    config.enableLongPress = true
    config.searchEnabled = true
    
    super.init(coordinator: coordinator, configuration: config)
    
    // Set ourselves as delegate to adapt to drawer pattern
    self.delegate = self
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - ChatKitConversationListViewControllerDelegate

extension DrawerViewController: ChatKitConversationListViewControllerDelegate {
  func conversationListViewController(
    _ controller: ChatKitConversationListViewController,
    didSelectConversation record: ConversationRecord
  ) {
    drawerDelegate?.drawerDidSelectConversation(sessionId: record.id)
  }
  
  func conversationListViewControllerDidRequestNewConversation(
    _ controller: ChatKitConversationListViewController
  ) {
    drawerDelegate?.drawerDidRequestNewConversation()
  }
  
  func conversationListViewController(
    _ controller: ChatKitConversationListViewController,
    didPinConversation record: ConversationRecord
  ) {
    // Pin functionality - can be implemented later
    print("Pin conversation: \(record.title)")
  }
}
