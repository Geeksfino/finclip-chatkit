//
//  AgentCatalog.m
//  SimpleChatObjC
//
//  Static catalog of available agents
//

#import "AgentCatalog.h"
#import "AgentProfile.h"
#import "ConnectionMode.h"

@implementation StaticAgentCatalog

+ (NSArray<AgentProfile *> *)defaultAgents {
    static NSArray<AgentProfile *> *agents = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray<AgentProfile *> *mutableAgents = [NSMutableArray array];
        
        // Parrot Echo - Fixture agent
        AgentProfile *parrotEcho = [[AgentProfile alloc] initWithAgentId:[[NSUUID alloc] initWithUUIDString:@"2C7915AB-4B3A-4877-AED0-9C1FA2B0E641"]
                                                                     name:@"Parrot Echo"
                                                              description:@"Local echo agent that repeats user input for demo purposes."
                                                                  address:[NSURL URLWithString:@"https://mock-fixture.local"]
                                                           connectionMode:[ConnectionMode fixtureMode]];
        [mutableAgents addObject:parrotEcho];
        
        // My Agent - Remote agent
        NSURL *remoteURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
        AgentProfile *myAgent = [[AgentProfile alloc] initWithAgentId:[[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"]
                                                                 name:@"My Agent"
                                                          description:@"Sample remote agent served from localhost gateway."
                                                              address:remoteURL
                                                       connectionMode:[ConnectionMode remoteModeWithURL:remoteURL]];
        [mutableAgents addObject:myAgent];
        
        // Loan Manager - Fixture agent
        AgentProfile *loanManager = [[AgentProfile alloc] initWithAgentId:[[NSUUID alloc] initWithUUIDString:@"F2F83C4E-956E-5E6E-C7DB-6661F3754F7C"]
                                                                      name:@"Loan Manager"
                                                               description:@"Handles loan applications and inquiries."
                                                                   address:[NSURL URLWithString:@"https://mock-fixture.local"]
                                                            connectionMode:[ConnectionMode fixtureMode]];
        [mutableAgents addObject:loanManager];
        
        // Customer Service - Fixture agent
        AgentProfile *customerService = [[AgentProfile alloc] initWithAgentId:[[NSUUID alloc] initWithUUIDString:@"A3A94D5F-A67F-6F7F-D8EC-7772A4865A8D"]
                                                                          name:@"Customer Service"
                                                                   description:@"Provides customer support and account assistance."
                                                                       address:[NSURL URLWithString:@"https://mock-fixture.local"]
                                                                connectionMode:[ConnectionMode fixtureMode]];
        [mutableAgents addObject:customerService];
        
        // Credit Officer - Fixture agent
        AgentProfile *creditOfficer = [[AgentProfile alloc] initWithAgentId:[[NSUUID alloc] initWithUUIDString:@"B4B05E6F-B78F-7F8F-E9FD-8883B5976B9E"]
                                                                        name:@"Credit Officer"
                                                                 description:@"Manages credit inquiries and credit limit adjustments."
                                                                     address:[NSURL URLWithString:@"https://mock-fixture.local"]
                                                              connectionMode:[ConnectionMode fixtureMode]];
        [mutableAgents addObject:creditOfficer];
        
        agents = [mutableAgents copy];
    });
    
    return agents;
}

@end


