import Foundation

struct AgentProfile: Identifiable, Equatable {
  let id: UUID
  let name: String
  let description: String
  let address: URL
  let connectionMode: ConnectionMode
}

protocol AgentCatalog {
  func loadAgents() async throws -> [AgentProfile]
}

struct StaticAgentCatalog: AgentCatalog {
  private let agents: [AgentProfile]

  init(agents: [AgentProfile] = StaticAgentCatalog.defaultAgents) {
    self.agents = agents
  }

  func loadAgents() async throws -> [AgentProfile] {
    agents
  }
}

extension StaticAgentCatalog {
  static var defaultAgents: [AgentProfile] {
    [
      AgentProfile(
        id: UUID(uuidString: "2C7915AB-4B3A-4877-AED0-9C1FA2B0E641")!,
        name: "Parrot Echo",
        description: "Local echo agent that repeats user input for demo purposes.",
        address: URL(string: "https://mock-fixture.local")!,
        connectionMode: .fixture
      ),
      AgentProfile(
        id: UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!,
        name: "Personal Banking",
        description: "Sample remote agent served from localhost gateway.",
        address: URL(string: "http://127.0.0.1:3000/agent")!,
        connectionMode: .remote(URL(string: "http://127.0.0.1:3000/agent")!)
      ),
      AgentProfile(
        id: UUID(uuidString: "F2F83C4E-956E-5E6E-C7DB-6661F3754F7C")!,
        name: "Loan Manager",
        description: "Handles loan applications and inquiries.",
        address: URL(string: "https://mock-fixture.local")!,
        connectionMode: .fixture
      ),
      AgentProfile(
        id: UUID(uuidString: "A3A94D5F-A67F-6F7F-D8EC-7772A4865A8D")!,
        name: "Customer Service",
        description: "Provides customer support and account assistance.",
        address: URL(string: "https://mock-fixture.local")!,
        connectionMode: .fixture
      ),
      AgentProfile(
        id: UUID(uuidString: "B4B05E6F-B78F-7F8F-E9FD-8883B5976B9E")!,
        name: "Credit Officer",
        description: "Manages credit inquiries and credit limit adjustments.",
        address: URL(string: "https://mock-fixture.local")!,
        connectionMode: .fixture
      )
    ]
  }
}
