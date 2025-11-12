//
//  ConversationListViewController.h
//  SimpleChatObjC
//
//  Conversation list screen for SimpleChatObjC - Refactored to use ChatKitConversationListViewController
//

#import <UIKit/UIKit.h>
@import FinClipChatKit;

@class ChatCoordinator;
@class CKTChatKitCoordinator;

NS_ASSUME_NONNULL_BEGIN

/// Conversation list with search and delete functionality
/// Uses ChatKitConversationListViewController internally via composition
@interface ConversationListViewController : UIViewController

/// Flag to auto-create first conversation on appear
@property (nonatomic, assign) BOOL autoCreateConversation;

/// Initialize with coordinator (deprecated - use initWithSDKCoordinator:)
/// @param coordinator The chat coordinator instance
- (instancetype)initWithCoordinator:(ChatCoordinator *)coordinator;

/// Initialize with SDK coordinator (recommended)
/// @param coordinator The CKTChatKitCoordinator instance
- (instancetype)initWithSDKCoordinator:(CKTChatKitCoordinator *)coordinator;

@end

NS_ASSUME_NONNULL_END

