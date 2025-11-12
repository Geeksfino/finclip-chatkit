//
//  ConversationRecord.m
//  SimpleChatObjC
//
//  App-level conversation record model
//

#import "ConversationRecord.h"
#import "ConnectionMode.h"
@import FinClipChatKit;
#import <FinClipChatKit/ChatKit-ObjC.h>

@implementation ConversationRecord

- (instancetype)initWithSessionId:(NSUUID *)sessionId
                          agentId:(NSUUID *)agentId
                        agentName:(NSString *)agentName
                            title:(NSString *)title
               lastMessagePreview:(nullable NSString *)lastMessagePreview
                        createdAt:(NSDate *)createdAt
                        updatedAt:(NSDate *)updatedAt
                       connection:(ConnectionMode *)connection {
    self = [super init];
    if (self) {
        _sessionId = sessionId;
        _agentId = agentId;
        _agentName = [agentName copy];
        _title = [title copy];
        _lastMessagePreview = [lastMessagePreview copy];
        _createdAt = createdAt;
        _updatedAt = updatedAt;
        _connection = connection;
    }
    return self;
}

- (instancetype)initWithSDKRecord:(id)sdkRecord connectionMode:(ConnectionMode *)connectionMode {
    // Map from SDK's CKTConversationRecord
    if ([sdkRecord isKindOfClass:NSClassFromString(@"CKTConversationRecord")]) {
        // Use runtime introspection to access properties
        NSUUID *sessionId = [sdkRecord valueForKey:@"sessionId"];
        NSUUID *agentId = [sdkRecord valueForKey:@"agentId"];
        NSString *title = [sdkRecord valueForKey:@"title"];
        NSString *lastMessagePreview = [sdkRecord valueForKey:@"lastMessagePreview"];
        NSDate *lastUpdatedAt = [sdkRecord valueForKey:@"lastUpdatedAt"];
        
        return [self initWithSessionId:sessionId ?: [[NSUUID alloc] init]
                                agentId:agentId ?: [[NSUUID alloc] init]
                              agentName:@"" // SDK doesn't track agent name
                                  title:title ?: @""
                     lastMessagePreview:lastMessagePreview
                              createdAt:[NSDate date] // SDK doesn't track creation time
                              updatedAt:lastUpdatedAt ?: [NSDate date]
                             connection:connectionMode];
    }
    
    // Fallback
    return [self initWithSessionId:[[NSUUID alloc] init]
                           agentId:[[NSUUID alloc] init]
                         agentName:@""
                             title:@""
                lastMessagePreview:nil
                         createdAt:[NSDate date]
                         updatedAt:[NSDate date]
                        connection:connectionMode];
}

- (NSString *)lastUpdatedDescription {
    NSRelativeDateTimeFormatter *formatter = [[NSRelativeDateTimeFormatter alloc] init];
    formatter.unitsStyle = NSRelativeDateTimeFormatterUnitsStyleShort;
    return [formatter localizedStringForDate:self.updatedAt relativeToDate:[NSDate date]];
}

- (ConversationRecord *)recordByUpdatingLastMessage:(nullable NSString *)text {
    return [[ConversationRecord alloc] initWithSessionId:self.sessionId
                                                  agentId:self.agentId
                                                agentName:self.agentName
                                                    title:self.title
                                       lastMessagePreview:text
                                                createdAt:self.createdAt
                                                updatedAt:[NSDate date]
                                               connection:self.connection];
}

- (ConversationRecord *)recordByRenamingTo:(NSString *)newTitle {
    return [[ConversationRecord alloc] initWithSessionId:self.sessionId
                                                  agentId:self.agentId
                                                agentName:self.agentName
                                                    title:newTitle
                                       lastMessagePreview:self.lastMessagePreview
                                                createdAt:self.createdAt
                                                updatedAt:[NSDate date]
                                               connection:self.connection];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ConversationRecord *copy = [[ConversationRecord alloc] initWithSessionId:self.sessionId
                                                                     agentId:self.agentId
                                                                   agentName:self.agentName
                                                                       title:self.title
                                                          lastMessagePreview:self.lastMessagePreview
                                                                   createdAt:self.createdAt
                                                                   updatedAt:self.updatedAt
                                                                  connection:self.connection];
    copy.isPinned = self.isPinned;
    return copy;
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[ConversationRecord class]]) return NO;
    
    ConversationRecord *other = (ConversationRecord *)object;
    return [self.sessionId isEqual:other.sessionId] &&
           [self.agentId isEqual:other.agentId] &&
           [self.agentName isEqual:other.agentName] &&
           [self.title isEqual:other.title] &&
           ((self.lastMessagePreview == nil && other.lastMessagePreview == nil) ||
            [self.lastMessagePreview isEqual:other.lastMessagePreview]) &&
           [self.createdAt isEqual:other.createdAt] &&
           [self.updatedAt isEqual:other.updatedAt] &&
           [self.connection isEqual:other.connection] &&
           ((self.isPinned == nil && other.isPinned == nil) ||
            [self.isPinned isEqual:other.isPinned]);
}

- (NSUInteger)hash {
    return [self.sessionId hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ConversationRecord(sessionId: %@, title: %@, agent: %@)",
            self.sessionId.UUIDString, self.title, self.agentName];
}

@end

