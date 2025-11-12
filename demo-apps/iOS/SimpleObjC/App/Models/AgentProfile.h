//
//  AgentProfile.h
//  SimpleChatObjC
//
//  Agent profile model for managing AI agents
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ConnectionMode;

/// Represents an AI agent profile
@interface AgentProfile : NSObject <NSCopying>

/// Unique identifier for the agent
@property (nonatomic, readonly) NSUUID *agentId;

/// Display name of the agent
@property (nonatomic, readonly) NSString *name;

/// Description of the agent's capabilities
@property (nonatomic, readonly) NSString *agentDescription;

/// Server address URL for the agent
@property (nonatomic, readonly) NSURL *address;

/// Connection mode (fixture or remote)
@property (nonatomic, readonly) ConnectionMode *connectionMode;

/// Initialize an agent profile
///
/// - Parameters:
///   - agentId: Unique identifier
///   - name: Display name
///   - description: Agent description
///   - address: Server URL
///   - connectionMode: Connection mode
- (instancetype)initWithAgentId:(NSUUID *)agentId
                            name:(NSString *)name
                     description:(NSString *)description
                         address:(NSURL *)address
                  connectionMode:(ConnectionMode *)connectionMode;

/// Initialize from dictionary (for convenience)
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END


