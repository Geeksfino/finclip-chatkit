//
//  AgentInfo.m
//  AI-Bank-OC
//
//  Model representing an AI agent's information
//

#import "AgentInfo.h"

@implementation AgentInfo

- (NSString *)description {
    return [NSString stringWithFormat:@"AgentInfo(id: %@, name: %@, description: %@)",
            self.agentId, self.name, self.agentDescription];
}

@end


