import Foundation
import Combine
import UIKit
import FinClipChatKit

enum ConnectionMode: Equatable {
  case fixture
  case remote(URL)
}

// MARK: - Network Adapter Protocol
// Note: This protocol should match what NeuronKit expects
// We're defining it here based on the README documentation pattern
// Actual protocol may differ - will be refined based on compilation errors

protocol NetworkAdapter {
  func connect() async throws
  func disconnect()
  func send(message: String) async throws
  func onMessage(_ handler: @escaping (Data) -> Void)
}

@MainActor
final class RuntimeCoordinator {
  private var runtime: NeuronRuntime?
  private let conversationManager = ConversationManager()
  private var connectionMode: ConnectionMode = .fixture
  private var cancellables = Set<AnyCancellable>()
  private let agentCatalog = StaticAgentCatalog()
  private var activeAgent: AgentProfile?
  private var activeDeviceId: String = "demo-device"

  private let stateSubject = CurrentValueSubject<String, Never>("Disconnected")
  private let errorSubject = PassthroughSubject<String, Never>()
  private let activeAgentSubject = CurrentValueSubject<AgentProfile?, Never>(nil)

  func statePublisher() -> AnyPublisher<String, Never> {
    stateSubject.eraseToAnyPublisher()
  }

  func errorPublisher() -> AnyPublisher<String, Never> {
    errorSubject.eraseToAnyPublisher()
  }
  
  func activeAgentPublisher() -> AnyPublisher<AgentProfile?, Never> {
    activeAgentSubject.eraseToAnyPublisher()
  }

  func connect(mode: ConnectionMode) {
    connectionMode = mode
    conversationManager.detach()
    conversationManager.setConnectionMode(mode)

    let config: NeuronKitConfig
    let agent: AgentProfile

    switch mode {
    case .fixture:
      let fixtureURL = URL(string: "https://mock-fixture.local")!
      activeDeviceId = "demo-device"
      agent = selectAgent(for: .fixture, remoteURL: fixtureURL)
      config = NeuronKitConfig(
        serverURL: fixtureURL,
        deviceId: activeDeviceId,
        userId: "demo-user",
        storage: .persistent
      )

    case .remote(let serverURL):
      activeDeviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
      agent = selectAgent(for: .remote(serverURL), remoteURL: serverURL)
      config = NeuronKitConfig(
        serverURL: serverURL,
        deviceId: activeDeviceId,
        userId: "demo-user",
        storage: .persistent
      )
    }

    let runtime = NeuronRuntime(config: config)
    activeAgent = agent
    activeAgentSubject.send(agent)
    conversationManager.attach(
      runtime: runtime,
      agent: agent,
      deviceId: activeDeviceId
    )

    if case .remote(let serverURL) = mode {
      let adapter = AGUI_Adapter(
        baseEventURL: serverURL,
        connectionMode: .postStream
      )
      runtime.setNetworkAdapter(adapter)
    }

    self.runtime = runtime

    configureSandbox(runtime: runtime)
    observeNetworkState(runtime: runtime)
    
    // Configure network adapter based on mode
    configureNetworkAdapter(runtime: runtime, mode: mode)

    stateSubject.send("Initialized")
  }
  
  private func configureNetworkAdapter(runtime: NeuronRuntime, mode: ConnectionMode) {
    switch mode {
    case .fixture:
      // Register MockSSEURLProtocol globally
      URLProtocol.registerClass(MockSSEURLProtocol.self)
      
      // Configure fixture mode using MockSSEURLProtocol in echo mode
      MockSSEURLProtocol.enableEchoMode(interval: 0.35)
      
      let mockURL = URL(string: "https://mock-sse.example.com/events")!
      
      // Create AGUI_Adapter with custom session factory that uses MockSSEURLProtocol
      // Use .postStream mode so SSE events come back on the POST response
      let mockAdapter = AGUI_Adapter(
        baseEventURL: mockURL,
        connectionMode: .postStream,
        sessionFactory: { configuration, delegate in
          // Create a new configuration with MockSSEURLProtocol
          let sessionConfig = URLSessionConfiguration.default
          sessionConfig.protocolClasses = [MockSSEURLProtocol.self]
          sessionConfig.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest
          sessionConfig.timeoutIntervalForResource = configuration.timeoutIntervalForResource
          return URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
        }
      )
      
      runtime.setNetworkAdapter(mockAdapter)
      
      print("🦜 Echo mode enabled - will respond with streaming prefix + user input")
      print("✅ Fixture adapter configured")
      
    case .remote:
      // For remote mode, NeuronKit uses its default adapter
      // Or we could create an AGUI_Adapter as shown in README:
      // let aguiAdapter = AGUI_Adapter(baseEventURL: serverURL, connectionMode: .postStream)
      // runtime.setNetworkAdapter(aguiAdapter)
      print("ℹ️  Using default remote adapter")
    }
  }

  func startConversation(title: String? = nil) -> (ConversationRecord, NeuronKit.Conversation)? {
    guard let agent = activeAgent else { return nil }
    return conversationManager.createConversation(agent: agent, title: title)
  }

  func disconnect() {
    conversationManager.detach()
    runtime = nil
    cancellables.removeAll()

    stateSubject.send("Disconnected")
  }
  
  func reconnect(mode: ConnectionMode) {
    // Detach current runtime but preserve conversation records
    conversationManager.detach()
    runtime = nil
    cancellables.removeAll()
    
    // Connect with new mode
    connect(mode: mode)
  }
  
  func setActiveAgent(_ agent: AgentProfile) {
    activeAgent = agent
    activeAgentSubject.send(agent)
    conversationManager.setActiveAgent(agent)
  }

  // MARK: - Conversation Accessors

  func recordsPublisher() -> AnyPublisher<[ConversationRecord], Never> {
    conversationManager.recordsPublisher
  }

  func recordsSnapshot() -> [ConversationRecord] {
    conversationManager.recordsSnapshot()
  }

  func conversation(for sessionId: UUID) -> NeuronKit.Conversation? {
    conversationManager.conversation(for: sessionId)
  }

  func record(for sessionId: UUID) -> ConversationRecord? {
    conversationManager.record(for: sessionId)
  }

  func removeConversation(sessionId: UUID) {
    conversationManager.unregister(sessionId: sessionId)
  }

  func updateTitle(sessionId: UUID, title: String) {
    conversationManager.updateTitle(for: sessionId, title: title)
  }

  private func selectAgent(for mode: ConnectionMode, remoteURL: URL) -> AgentProfile {
    switch mode {
    case .fixture:
      if let fixtureAgent = StaticAgentCatalog.defaultAgents.first(where: { profile in
        if case .fixture = profile.connectionMode { return true }
        return false
      }) {
        return fixtureAgent
      }
      return StaticAgentCatalog.defaultAgents.first ?? AgentProfile(
        id: UUID(),
        name: "Fixture Agent",
        description: "Built-in fixture agent",
        address: remoteURL,
        connectionMode: .fixture
      )

    case .remote(let url):
      if let matching = StaticAgentCatalog.defaultAgents.first(where: { profile in
        if case .remote(let agentURL) = profile.connectionMode {
          return agentURL == url
        }
        return false
      }) {
        return matching
      }
      if let template = StaticAgentCatalog.defaultAgents.first(where: { profile in
        if case .remote = profile.connectionMode { return true }
        return false
      }) {
        return AgentProfile(
          id: template.id,
          name: template.name,
          description: template.description,
          address: url,
          connectionMode: .remote(url)
        )
      }
      return AgentProfile(
        id: UUID(),
        name: "Remote Agent",
        description: "Custom remote agent",
        address: url,
        connectionMode: .remote(url)
      )
    }
  }

  private func configureSandbox(runtime: NeuronRuntime) {
    let cameraFeature = SandboxSDK.Feature(
      id: "camera_capture",
      name: "Camera Capture",
      description: "Take a photo using device camera",
      category: .Native,
      path: "/camera",
      requiredCapabilities: [.UIAccess],
      primitives: [.MobileUI(page: "/camera", component: nil)]
    )

    let paymentFeature = SandboxSDK.Feature(
      id: "process_payment",
      name: "Process Payment",
      description: "Process a payment transaction",
      category: .Native,
      path: "/payment",
      requiredCapabilities: [.UIAccess, .Network],
      primitives: [
        .MobileUI(page: "/payment", component: nil),
        .NetworkOp(url: "/api/payments", method: "POST")
      ]
    )

    _ = runtime.sandbox.registerFeature(cameraFeature)
    _ = runtime.sandbox.setPolicy(
      cameraFeature.id,
      SandboxSDK.Policy(
        requiresUserPresent: true,
        requiresExplicitConsent: true,
        sensitivity: .medium,
        rateLimit: SandboxSDK.RateLimit(unit: .minute, max: 10)
      )
    )

    _ = runtime.sandbox.registerFeature(paymentFeature)
    _ = runtime.sandbox.setPolicy(
      paymentFeature.id,
      SandboxSDK.Policy(
        requiresUserPresent: true,
        requiresExplicitConsent: true,
        sensitivity: .high,
        rateLimit: SandboxSDK.RateLimit(unit: .day, max: 5)
      )
    )
  }

  private func observeNetworkState(runtime: NeuronRuntime) {
    runtime.networkStatePublisher()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        switch state {
        case .connected:
          self?.stateSubject.send("Connected")
        case .connecting:
          self?.stateSubject.send("Connecting...")
        case .reconnecting:
          self?.stateSubject.send("Reconnecting...")
        case .disconnected:
          self?.stateSubject.send("Disconnected")
        case .error(let error):
          self?.errorSubject.send(error.message)
          self?.stateSubject.send("Disconnected")
        @unknown default:
          self?.stateSubject.send("Unknown state")
        }
      }
      .store(in: &cancellables)
  }
}
