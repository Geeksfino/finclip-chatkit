//
//  ChatViewController.h
//  SimpleChatObjC
//
//  Chat view controller with ChatHostingController wrapper
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ConversationRecord;

/// Chat view controller with ChatHostingController wrapper
/// NOTE: This is deprecated. Use ChatKitConversationViewController directly.
@interface ChatViewController : UIViewController

/// Session identifier
@property (nonatomic, readonly) NSUUID *sessionIdentifier;

- (instancetype)initWithRecord:(ConversationRecord *)record
                       adapter:(id)adapter
                    coordinator:(id)coordinator;

@end

NS_ASSUME_NONNULL_END
