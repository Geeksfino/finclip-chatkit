//
//  ConversationListViewController.h
//  SimpleChatObjC
//
//  Thin wrapper around ChatKitConversationListViewController
//

#import <UIKit/UIKit.h>
@import FinClipChatKit;

NS_ASSUME_NONNULL_BEGIN

/// Thin wrapper that embeds ChatKitConversationListViewController
@interface ConversationListViewController : UIViewController

/// Initialize with SDK coordinator
- (instancetype)initWithCoordinator:(CKTChatKitCoordinator *)coordinator NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
