//
//  RuntimeCoordinator.h
//  AI-Bank-OC
//
//  Coordinates ChatKit runtime and agent interactions
//

#import <Foundation/Foundation.h>

@class AgentInfo;
@class ConversationManager;

@interface RuntimeCoordinator : NSObject

- (instancetype)initWithConversationManager:(ConversationManager *)conversationManager;

- (void)loadAgentWithInfo:(AgentInfo *)agentInfo;
- (void)sendMessage:(NSString *)message completion:(void (^)(NSString *response, NSError *error))completion;

@end


