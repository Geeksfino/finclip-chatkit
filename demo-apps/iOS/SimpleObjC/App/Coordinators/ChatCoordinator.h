//
//  ChatCoordinator.h
//  SimpleChatObjC
//
//  Application-level coordinator using ChatKit's Level 1 API
//

#import <Foundation/Foundation.h>

@class CKTChatKitCoordinator;
@class CKTConversationManager;
@class CKTConversationRecord;
@protocol ChatCoordinatorDelegate;

NS_ASSUME_NONNULL_BEGIN

/// Application coordinator managing connection and conversations
@interface ChatCoordinator : NSObject

/// Delegate for state updates
@property (nonatomic, weak, nullable) id<ChatCoordinatorDelegate> delegate;

/// Current connection state description
@property (nonatomic, readonly) NSString *currentState;

/// Initialize coordinator
- (instancetype)init;

/// Connect to the server
- (void)connect;

/// Disconnect and cleanup
- (void)disconnect;

/// Create a new conversation
/// @param title Optional conversation title
/// @param completion Completion handler with record and conversation
- (void)createConversationWithTitle:(NSString * _Nullable)title
                         completion:(void (^)(CKTConversationRecord * _Nullable record, 
                                            id _Nullable conversation,
                                            NSError * _Nullable error))completion;

/// Get conversation by session ID
/// @param sessionId The session identifier
/// @returns The conversation object or nil
- (nullable id)conversationForSessionId:(NSUUID *)sessionId;

/// Delete conversation
/// @param sessionId The session identifier
- (void)deleteConversationWithSessionId:(NSUUID *)sessionId;

/// Get all conversation records
/// @returns Array of conversation records
- (NSArray<CKTConversationRecord *> *)allConversations;

/// Access to conversation manager (for delegate registration)
@property (nonatomic, readonly, nullable) CKTConversationManager *conversationManager;

@end

/// Delegate protocol for coordinator state updates
@protocol ChatCoordinatorDelegate <NSObject>

@optional

/// Called when connection state changes
/// @param coordinator The coordinator instance
/// @param state State description string
- (void)chatCoordinator:(ChatCoordinator *)coordinator didChangeState:(NSString *)state;

/// Called when an error occurs
/// @param coordinator The coordinator instance
/// @param error The error that occurred
- (void)chatCoordinator:(ChatCoordinator *)coordinator didEncounterError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END

