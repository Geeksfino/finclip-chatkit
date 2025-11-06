//
//  RuntimeCoordinator.m
//  AI-Bank-OC
//
//  Coordinates ChatKit runtime and agent interactions
//
//  This coordinator demonstrates how to use ChatKit from Objective-C:
//  1. Initialize the ChatKit runtime
//  2. Load and configure agents
//  3. Send messages and handle responses
//  4. Manage conversation state
//

#import "RuntimeCoordinator.h"
#import "ConversationManager.h"
#import "AgentInfo.h"
@import FinClipChatKit;

@interface RuntimeCoordinator ()

@property (nonatomic, strong) ConversationManager *conversationManager;
@property (nonatomic, strong) AgentInfo *currentAgentInfo;
// In a real implementation, you would have a ChatKit runtime object here
// @property (nonatomic, strong) ChatKitRuntime *chatKitRuntime;

@end

@implementation RuntimeCoordinator

- (instancetype)initWithConversationManager:(ConversationManager *)conversationManager {
    self = [super init];
    if (self) {
        _conversationManager = conversationManager;
        [self setupChatKitRuntime];
    }
    return self;
}

- (void)setupChatKitRuntime {
    // Initialize ChatKit runtime
    // In a real implementation:
    // self.chatKitRuntime = [[ChatKitRuntime alloc] initWithConfiguration:config];
    
    NSLog(@"ChatKit runtime initialized");
}

- (void)loadAgentWithInfo:(AgentInfo *)agentInfo {
    self.currentAgentInfo = agentInfo;
    
    NSLog(@"Loading agent: %@ with URL: %@", agentInfo.name, agentInfo.serverURL);
    
    // Configure ChatKit with agent information
    // In a real implementation:
    // [self.chatKitRuntime loadAgentWithConfiguration:agentConfig];
    
    // Create new conversation
    [self.conversationManager createConversationWithAgentId:agentInfo.agentId];
}

- (void)sendMessage:(NSString *)message completion:(void (^)(NSString *response, NSError *error))completion {
    if (!self.currentAgentInfo) {
        NSError *error = [NSError errorWithDomain:@"RuntimeCoordinatorError"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"No agent loaded"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    NSLog(@"Sending message to agent %@: %@", self.currentAgentInfo.name, message);
    
    // Add message to conversation
    [self.conversationManager addMessage:message fromUser:YES];
    
    // Send message through ChatKit
    // In a real implementation:
    // [self.chatKitRuntime sendMessage:message completion:^(ChatKitResponse *response, NSError *error) {
    //     if (error) {
    //         completion(nil, error);
    //         return;
    //     }
    //     [self.conversationManager addMessage:response.text fromUser:NO];
    //     completion(response.text, nil);
    // }];
    
    // Simulate agent response for demonstration
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *simulatedResponse = [NSString stringWithFormat:@"This is a simulated response from %@ to your message: '%@'. In a real implementation, this would be the actual response from the ChatKit agent.",
                                      self.currentAgentInfo.name, message];
        
        [self.conversationManager addMessage:simulatedResponse fromUser:NO];
        
        if (completion) {
            completion(simulatedResponse, nil);
        }
    });
}

@end


