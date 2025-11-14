import UIKit
import FinClipChatKit
import ConvoUI
import NeuronKit

/// Simplified ChatViewController using ChatKitConversationViewController
///
/// This is now a thin wrapper that configures ChatKitConversationViewController
/// with app-specific settings (welcome message, tools, context providers).
final class ChatViewController: ChatKitConversationViewController {
  
  init(record: FinClipChatKit.ConversationRecord, conversation: NeuronKit.Conversation, coordinator: ChatKitCoordinator) {
    // Configure with app-specific settings
    var config = ChatKitConversationConfiguration.default
    config.showStatusBanner = true
    config.showWelcomeMessage = true
    config.welcomeMessageProvider = { LocalizationHelper.localized("app.welcome") }
    config.toolsProvider = { ComposerToolsExample.createExampleTools() }
    // Wrap in MainActor.assumeIsolated since this init is called from MainActor context
    config.contextProvidersProvider = {
      MainActor.assumeIsolated {
        ChatContextProviderFactory.makeDefaultProviders()
      }
    }
    config.statusBannerAutoHide = true
    config.statusBannerAutoHideDelay = 2.0
    
    super.init(record: record, conversation: conversation, coordinator: coordinator, configuration: config)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var sessionIdentifier: UUID {
    record.id
  }
}
