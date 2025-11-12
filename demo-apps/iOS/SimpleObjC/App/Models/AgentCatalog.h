//
//  AgentCatalog.h
//  SimpleChatObjC
//
//  Static catalog of available agents
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AgentProfile;

/// Static catalog of available AI agents
@interface StaticAgentCatalog : NSObject

/// Default list of agents
+ (NSArray<AgentProfile *> *)defaultAgents;

@end

NS_ASSUME_NONNULL_END


