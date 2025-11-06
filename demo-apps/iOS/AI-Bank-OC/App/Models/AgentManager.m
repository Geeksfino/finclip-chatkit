//
//  AgentManager.m
//  AI-Bank-OC
//
//  Manages agent lifecycle and interactions with ChatKit
//

#import "AgentManager.h"

@interface AgentManager ()

@property (nonatomic, strong, readwrite) AgentInfo *currentAgent;

@end

@implementation AgentManager

- (void)loadAgent:(AgentInfo *)agentInfo {
    if (self.currentAgent) {
        [self unloadAgent];
    }
    
    self.currentAgent = agentInfo;
    NSLog(@"Loaded agent: %@", agentInfo.name);
    
    // Here you would initialize the ChatKit runtime with the agent configuration
    // Example: [self.chatKitRuntime configureWithAgent:agentInfo];
}

- (void)unloadAgent {
    if (self.currentAgent) {
        NSLog(@"Unloading agent: %@", self.currentAgent.name);
        self.currentAgent = nil;
        
        // Here you would clean up ChatKit runtime resources
        // Example: [self.chatKitRuntime cleanup];
    }
}

@end


