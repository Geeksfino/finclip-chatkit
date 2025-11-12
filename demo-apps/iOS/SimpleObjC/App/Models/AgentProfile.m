//
//  AgentProfile.m
//  SimpleChatObjC
//
//  Agent profile model for managing AI agents
//

#import "AgentProfile.h"
#import "ConnectionMode.h"

@implementation AgentProfile

- (instancetype)initWithAgentId:(NSUUID *)agentId
                            name:(NSString *)name
                     description:(NSString *)description
                         address:(NSURL *)address
                  connectionMode:(ConnectionMode *)connectionMode {
    self = [super init];
    if (self) {
        _agentId = agentId;
        _name = [name copy];
        _agentDescription = [description copy];
        _address = address;
        _connectionMode = connectionMode;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    NSUUID *agentId = dictionary[@"agentId"];
    if (!agentId && dictionary[@"id"]) {
        NSString *uuidString = dictionary[@"id"];
        agentId = [[NSUUID alloc] initWithUUIDString:uuidString];
    }
    
    NSString *name = dictionary[@"name"] ?: @"Unknown Agent";
    NSString *description = dictionary[@"description"] ?: @"";
    NSURL *address = dictionary[@"address"];
    if ([address isKindOfClass:[NSString class]]) {
        address = [NSURL URLWithString:(NSString *)address];
    }
    
    ConnectionMode *mode = dictionary[@"connectionMode"];
    if (!mode) {
        // Default to fixture if not specified
        mode = [ConnectionMode fixtureMode];
    }
    
    return [self initWithAgentId:agentId
                             name:name
                      description:description
                          address:address
                   connectionMode:mode];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return [[AgentProfile alloc] initWithAgentId:self.agentId
                                            name:self.name
                                     description:self.agentDescription
                                         address:self.address
                                  connectionMode:[self.connectionMode copy]];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[AgentProfile class]]) return NO;
    
    AgentProfile *other = (AgentProfile *)object;
    return [self.agentId isEqual:other.agentId] &&
           [self.name isEqual:other.name] &&
           [self.agentDescription isEqual:other.agentDescription] &&
           [self.address isEqual:other.address] &&
           [self.connectionMode isEqual:other.connectionMode];
}

- (NSUInteger)hash {
    return [self.agentId hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"AgentProfile(id: %@, name: %@, mode: %@)",
            self.agentId.UUIDString, self.name, self.connectionMode];
}

@end


