//
//  ConversationRecord.m
//  AI-Bank-OC
//
//  Model representing a conversation record
//

#import "ConversationRecord.h"

@implementation ConversationRecord

- (instancetype)init {
    self = [super init];
    if (self) {
        _conversationId = [[NSUUID UUID] UUIDString];
        _createdAt = [NSDate date];
        _updatedAt = [NSDate date];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ConversationRecord(id: %@, title: %@, agentId: %@)",
            self.conversationId, self.title, self.agentId];
}

@end


