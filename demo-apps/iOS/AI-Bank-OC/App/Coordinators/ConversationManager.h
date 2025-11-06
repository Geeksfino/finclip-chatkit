//
//  ConversationManager.h
//  AI-Bank-OC
//
//  Manages conversation records and message history
//

#import <Foundation/Foundation.h>

@class ConversationRecord;

@interface ConversationManager : NSObject

@property (nonatomic, strong, readonly) ConversationRecord *currentConversation;
@property (nonatomic, strong, readonly) NSArray<ConversationRecord *> *allConversations;

- (void)createConversationWithAgentId:(NSString *)agentId;
- (void)loadConversation:(ConversationRecord *)conversation;
- (void)addMessage:(NSString *)message fromUser:(BOOL)isFromUser;
- (void)deleteConversation:(ConversationRecord *)conversation;

@end


