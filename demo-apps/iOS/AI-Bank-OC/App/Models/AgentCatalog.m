//
//  AgentCatalog.m
//  AI-Bank-OC
//
//  Manages catalog of available AI agents
//

#import "AgentCatalog.h"

@interface AgentCatalog ()

@property (nonatomic, strong, readwrite) NSArray<AgentInfo *> *agents;

@end

@implementation AgentCatalog

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadAgents];
    }
    return self;
}

- (void)loadAgents {
    NSMutableArray *agentArray = [NSMutableArray array];
    
    // Banking Assistant Agent
    AgentInfo *bankingAssistant = [[AgentInfo alloc] init];
    bankingAssistant.agentId = @"banking-assistant";
    bankingAssistant.name = @"Banking Assistant";
    bankingAssistant.agentDescription = @"Your personal banking assistant for account inquiries, transactions, and financial advice";
    bankingAssistant.serverURL = @"https://api.example.com/banking-agent";
    [agentArray addObject:bankingAssistant];
    
    // Investment Advisor Agent
    AgentInfo *investmentAdvisor = [[AgentInfo alloc] init];
    investmentAdvisor.agentId = @"investment-advisor";
    investmentAdvisor.name = @"Investment Advisor";
    investmentAdvisor.agentDescription = @"Get personalized investment recommendations and portfolio analysis";
    investmentAdvisor.serverURL = @"https://api.example.com/investment-agent";
    [agentArray addObject:investmentAdvisor];
    
    // Loan Calculator Agent
    AgentInfo *loanCalculator = [[AgentInfo alloc] init];
    loanCalculator.agentId = @"loan-calculator";
    loanCalculator.name = @"Loan Calculator";
    loanCalculator.agentDescription = @"Calculate loan payments, interest rates, and eligibility";
    loanCalculator.serverURL = @"https://api.example.com/loan-agent";
    [agentArray addObject:loanCalculator];
    
    self.agents = [agentArray copy];
}

- (AgentInfo *)agentWithId:(NSString *)agentId {
    for (AgentInfo *agent in self.agents) {
        if ([agent.agentId isEqualToString:agentId]) {
            return agent;
        }
    }
    return nil;
}

@end


