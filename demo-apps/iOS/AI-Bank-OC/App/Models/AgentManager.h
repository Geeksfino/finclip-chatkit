//
//  AgentManager.h
//  AI-Bank-OC
//
//  Manages agent lifecycle and interactions with ChatKit
//

#import <Foundation/Foundation.h>
#import "AgentInfo.h"

@interface AgentManager : NSObject

@property (nonatomic, strong, readonly) AgentInfo *currentAgent;

- (void)loadAgent:(AgentInfo *)agentInfo;
- (void)unloadAgent;

@end


