//
//  ChatCoordinator.m
//  SimpleChatObjC
//
//  Application-level coordinator using ChatKit's Level 1 API
//

#import "ChatCoordinator.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>
#import <UIKit/UIKit.h>

@interface ChatCoordinator () <CKTChatKitCoordinatorDelegate, CKTConversationManagerDelegate>

@property (nonatomic, strong, nullable) CKTChatKitCoordinator *chatKitCoordinator;
@property (nonatomic, strong, nullable) CKTConversationManager *conversationManager;
@property (nonatomic, copy) NSString *currentState;

@end

@implementation ChatCoordinator

// Default configuration
static NSString *const kDefaultServerURL = @"http://127.0.0.1:3000/agent";
static NSString *const kDefaultAgentID = @"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B";

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentState = @"Disconnected";
    }
    return self;
}

- (void)connect {
    // Get device ID
    NSString *deviceId = [UIDevice currentDevice].identifierForVendor.UUIDString;
    if (!deviceId) {
        deviceId = [NSUUID UUID].UUIDString;
    }
    
    // Create configuration
    NSURL *serverURL = [NSURL URLWithString:kDefaultServerURL];
    CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                             userId:@"demo-user"
                                                                           deviceId:deviceId];
    config.storageMode = CKTStorageModePersistent;
    
    // Use CKTChatKitCoordinator from SDK for safe runtime management
    CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
    coordinator.delegate = self;
    self.chatKitCoordinator = coordinator;
    
    // Use CKTConversationManager from SDK for conversation tracking
    CKTConversationManager *manager = [[CKTConversationManager alloc] init];
    [manager attachToCoordinator:coordinator];
    manager.delegate = self;
    self.conversationManager = manager;
    
    self.currentState = @"Initialized";
    [self.delegate chatCoordinator:self didChangeState:self.currentState];
}

- (void)disconnect {
    [self.conversationManager detach];
    self.conversationManager = nil;
    self.chatKitCoordinator = nil;
    
    self.currentState = @"Disconnected";
    [self.delegate chatCoordinator:self didChangeState:self.currentState];
}

- (void)createConversationWithTitle:(NSString *)title
                         completion:(void (^)(CKTConversationRecord *, id, NSError *))completion {
    if (!self.conversationManager) {
        NSError *error = [NSError errorWithDomain:@"com.finclip.simplechat"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Not connected"}];
        completion(nil, nil, error);
        return;
    }
    
    NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:kDefaultAgentID];
    
    [self.conversationManager createConversationWithAgentId:agentId
                                                      title:title
                                                  agentName:nil
                                                   deviceId:nil
                                                 completion:^(CKTConversationRecord * _Nullable record,
                                                            id _Nullable conversation,
                                                            NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(record, conversation, error);
        });
    }];
}

- (id)conversationForSessionId:(NSUUID *)sessionId {
    return [self.conversationManager conversationForSessionId:sessionId];
}

- (void)deleteConversationWithSessionId:(NSUUID *)sessionId {
    [self.conversationManager deleteConversationWithSessionId:sessionId];
}

- (NSArray<CKTConversationRecord *> *)allConversations {
    return self.conversationManager.records ?: @[];
}

#pragma mark - CKTChatKitCoordinatorDelegate

- (void)chatKitCoordinator:(CKTChatKitCoordinator *)coordinator didChangeState:(NSString *)state {
    self.currentState = state;
    [self.delegate chatCoordinator:self didChangeState:state];
}

- (void)chatKitCoordinator:(CKTChatKitCoordinator *)coordinator didEncounterError:(NSError *)error {
    [self.delegate chatCoordinator:self didEncounterError:error];
}

#pragma mark - CKTConversationManagerDelegate

- (void)conversationManager:(CKTConversationManager *)manager
          didUpdateRecords:(NSArray<CKTConversationRecord *> *)records {
    // Forward to any listeners who care about record updates
    // ConversationListViewController will observe this directly
}

@end

