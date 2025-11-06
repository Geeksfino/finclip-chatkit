//
//  ConversationManager.m
//  AI-Bank-OC
//
//  Manages conversation records and message history
//

#import "ConversationManager.h"
#import "ConversationRecord.h"

@interface ConversationManager () {
    NSMutableArray<ConversationRecord *> *_allConversations;
}

@property (nonatomic, strong, readwrite) ConversationRecord *currentConversation;

@end

@implementation ConversationManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _allConversations = [NSMutableArray array];
    }
    return self;
}

- (NSArray<ConversationRecord *> *)allConversations {
    return [_allConversations copy];
}

- (void)createConversationWithAgentId:(NSString *)agentId {
    ConversationRecord *conversation = [[ConversationRecord alloc] init];
    conversation.agentId = agentId;
    conversation.title = [NSString stringWithFormat:@"Conversation with %@", agentId];
    
    [_allConversations addObject:conversation];
    self.currentConversation = conversation;
    
    NSLog(@"Created new conversation: %@", conversation.conversationId);
}

- (void)loadConversation:(ConversationRecord *)conversation {
    self.currentConversation = conversation;
    NSLog(@"Loaded conversation: %@", conversation.conversationId);
}

- (void)addMessage:(NSString *)message fromUser:(BOOL)isFromUser {
    if (!self.currentConversation) {
        NSLog(@"Warning: No current conversation to add message to");
        return;
    }
    
    // Update conversation timestamp
    self.currentConversation.updatedAt = [NSDate date];
    
    // In a real implementation, you would persist the message
    NSLog(@"Added message to conversation %@: [%@] %@",
          self.currentConversation.conversationId,
          isFromUser ? @"User" : @"Agent",
          message);
}

- (void)deleteConversation:(ConversationRecord *)conversation {
    [_allConversations removeObject:conversation];
    
    if (self.currentConversation == conversation) {
        self.currentConversation = nil;
    }
    
    NSLog(@"Deleted conversation: %@", conversation.conversationId);
}

@end


