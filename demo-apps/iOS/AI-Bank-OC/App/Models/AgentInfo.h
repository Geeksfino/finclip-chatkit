//
//  AgentInfo.h
//  AI-Bank-OC
//
//  Model representing an AI agent's information
//

#import <Foundation/Foundation.h>

@interface AgentInfo : NSObject

@property (nonatomic, strong) NSString *agentId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *agentDescription;
@property (nonatomic, strong) NSString *serverURL;

@end


