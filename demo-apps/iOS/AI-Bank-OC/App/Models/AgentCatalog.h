//
//  AgentCatalog.h
//  AI-Bank-OC
//
//  Manages catalog of available AI agents
//

#import <Foundation/Foundation.h>
#import "AgentInfo.h"

@interface AgentCatalog : NSObject

@property (nonatomic, strong, readonly) NSArray<AgentInfo *> *agents;

- (AgentInfo *)agentWithId:(NSString *)agentId;

@end


