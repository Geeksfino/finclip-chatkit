//
//  ConversationRecord.h
//  SimpleChatObjC
//
//  App-level conversation record model
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ConnectionMode;

/// App-level conversation record (extends SDK's CKTConversationRecord)
@interface ConversationRecord : NSObject <NSCopying>

/// Session identifier
@property (nonatomic, readonly) NSUUID *sessionId;

/// Agent identifier
@property (nonatomic, readwrite) NSUUID *agentId;

/// Agent name (app-specific tracking)
@property (nonatomic, readwrite) NSString *agentName;

/// Conversation title
@property (nonatomic, readwrite) NSString *title;

/// Preview of last message
@property (nonatomic, readwrite, nullable) NSString *lastMessagePreview;

/// Creation timestamp
@property (nonatomic, readonly) NSDate *createdAt;

/// Last update timestamp
@property (nonatomic, readwrite) NSDate *updatedAt;

/// Connection mode
@property (nonatomic, readonly) ConnectionMode *connection;

/// Whether conversation is pinned
@property (nonatomic, readwrite, nullable) NSNumber *isPinned;

/// Initialize a conversation record
- (instancetype)initWithSessionId:(NSUUID *)sessionId
                          agentId:(NSUUID *)agentId
                        agentName:(NSString *)agentName
                            title:(NSString *)title
               lastMessagePreview:(nullable NSString *)lastMessagePreview
                        createdAt:(NSDate *)createdAt
                        updatedAt:(NSDate *)updatedAt
                       connection:(ConnectionMode *)connection;

/// Initialize from SDK's CKTConversationRecord
- (instancetype)initWithSDKRecord:(id)sdkRecord connectionMode:(ConnectionMode *)connectionMode;

/// Formatted relative time description (e.g. "5 min ago")
- (NSString *)lastUpdatedDescription;

/// Create updated record with new last message
- (ConversationRecord *)recordByUpdatingLastMessage:(nullable NSString *)text;

/// Create updated record with new title
- (ConversationRecord *)recordByRenamingTo:(NSString *)newTitle;

@end

NS_ASSUME_NONNULL_END


