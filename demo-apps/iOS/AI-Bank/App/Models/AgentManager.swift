import Foundation
import ConvoUI

final class DemoAgentManager: NSObject, FinConvoComposerAgentManager {
    private let agents: [FinConvoAgent]
    private var current: FinConvoAgent

    override init() {
        let loanManager = FinConvoAgent(id: "loan-manager", displayName: "Loan Manager")
        loanManager.isAvailable = true

        let customerService = FinConvoAgent(id: "customer-service", displayName: "Customer Service")
        customerService.isAvailable = true

        let creditOfficer = FinConvoAgent(id: "credit-officer", displayName: "Credit Officer")
        creditOfficer.isAvailable = true

        self.agents = [loanManager, customerService, creditOfficer]
        self.current = loanManager
        super.init()
    }

    func availableAgents() -> [FinConvoAgent] {
        agents
    }

    func currentAgent() -> FinConvoAgent {
        current
    }

    func didSelect(_ agent: FinConvoAgent) {
        current = agent
        NSLog("[AI-Bank] Selected agent: %@", agent.displayName)
    }
}
