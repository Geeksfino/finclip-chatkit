import Foundation
import Combine
import FinClipChatKit

@MainActor
final class ConversationManager {
  private weak var runtime: NeuronRuntime?
  private var connectionMode: ConnectionMode = .fixture
  private var records: [UUID: ConversationRecord] = [:]
  private var conversations: [UUID: NeuronKit.Conversation] = [:]
  private var subscriptions: [UUID: AnyCancellable] = [:]
  private var nextSessionIndex: Int = 1
  private var activeAgent: AgentProfile?
  private var deviceId: String = "demo-device"

  private let recordsSubject = CurrentValueSubject<[ConversationRecord], Never>([])
  var recordsPublisher: AnyPublisher<[ConversationRecord], Never> {
    recordsSubject.eraseToAnyPublisher()
  }

  func attach(
    runtime: NeuronRuntime,
    agent: AgentProfile,
    deviceId: String
  ) {
    self.runtime = runtime
    self.deviceId = deviceId
    setActiveAgent(agent)
  }
  
  func setActiveAgent(_ agent: AgentProfile) {
    guard activeAgent?.id != agent.id else {
      // Ensure existing records continue observing messages
      for (sessionId, _) in records {
        observeMessages(for: sessionId)
      }
      publish()
      return
    }
    activeAgent = agent
    hydratePersistedConversations(for: agent)
  }

  func detach() {
    // Unbind UIs but keep records for persistence
    conversations.values.forEach { $0.unbindUI() }
    conversations.removeAll()
    subscriptions.values.forEach { $0.cancel() }
    subscriptions.removeAll()
    runtime = nil
  }

  func setConnectionMode(_ mode: ConnectionMode) {
    connectionMode = mode
  }

  func recordsSnapshot() -> [ConversationRecord] {
    sortedRecords()
  }

  func createConversation(
    agent: AgentProfile,
    title: String? = nil
  ) -> (record: ConversationRecord, conversation: NeuronKit.Conversation)? {
    guard let runtime else { return nil }

    let sessionId = UUID()
    let conversation = runtime.openConversation(sessionId: sessionId, agentId: agent.id)
    
    // Ensure agent and conversation records exist in convstore
    Task {
      guard let repo = runtime.conversationRepository else { return }
      do {
        try await repo.ensureAgent(id: agent.id, name: agent.name)
        try await repo.ensureConversation(sessionId: sessionId, agentId: agent.id, deviceId: deviceId)
      } catch {
        print("Failed to ensure agent or conversation: \(error)")
      }
    }

    let resolvedTitle: String
    if let provided = title?.trimmingCharacters(in: .whitespacesAndNewlines), !provided.isEmpty {
      resolvedTitle = provided
    } else {
      resolvedTitle = "Session \(nextSessionIndex)"
      nextSessionIndex += 1
    }

    let now = Date()
    let record = ConversationRecord(
      sessionId: sessionId,
      agentId: agent.id,
      agentName: agent.name,
      title: resolvedTitle,
      lastMessagePreview: nil,
      createdAt: now,
      updatedAt: now,
      connection: connectionMode
    )

    store(record: record, conversation: conversation)
    return (record, conversation)
  }

  func register(_ record: ConversationRecord, conversation: NeuronKit.Conversation) {
    store(record: record, conversation: conversation)
  }

  func conversation(for sessionId: UUID) -> NeuronKit.Conversation? {
    if let existing = conversations[sessionId] {
      return existing
    }
    guard let runtime, let record = records[sessionId] else { return nil }
    let conversation = runtime.resumeConversation(sessionId: sessionId, agentId: record.agentId)
    conversations[sessionId] = conversation
    observeMessages(for: sessionId)
    return conversation
  }

  func record(for sessionId: UUID) -> ConversationRecord? {
    records[sessionId]
  }

  func updateTitle(for sessionId: UUID, title: String) {
    guard var record = records[sessionId] else { return }
    records[sessionId] = record.renaming(to: title)
    publish()
  }

  func unregister(sessionId: UUID) {
    conversations[sessionId]?.unbindUI()
    conversations.removeValue(forKey: sessionId)
    subscriptions[sessionId]?.cancel()
    subscriptions.removeValue(forKey: sessionId)
    records.removeValue(forKey: sessionId)
    publish()
  }

  func unregisterAll() {
    conversations.values.forEach { $0.unbindUI() }
    conversations.removeAll()
    subscriptions.values.forEach { $0.cancel() }
    subscriptions.removeAll()
    records.removeAll()
    nextSessionIndex = 1
    publish()
  }

  // MARK: - Private

  private func store(record: ConversationRecord, conversation: NeuronKit.Conversation) {
    records[record.sessionId] = record
    conversations[record.sessionId] = conversation
    observeMessages(for: record.sessionId)
    publish()
  }

  private func observeMessages(for sessionId: UUID) {
    guard let runtime else { return }
    subscriptions[sessionId]?.cancel()
    subscriptions[sessionId] = runtime
      .messagesPublisher(sessionId: sessionId, isDelta: true, initialSnapshot: .full)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] messages in
        self?.handleMessages(sessionId: sessionId, messages: messages)
      }
  }

  private func handleMessages(sessionId: UUID, messages: [NeuronMessage]) {
    guard !messages.isEmpty else { return }
    guard var record = records[sessionId] else { return }

    if let last = messages.last(where: { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
      record = record.updatingLastMessage(last.content)

      if (record.title.hasPrefix("Session ") || record.title == "New Conversation"),
         last.sender == .user {
        let snippet = String(last.content.prefix(40)).trimmingCharacters(in: .whitespacesAndNewlines)
        if !snippet.isEmpty {
          record = record.renaming(to: snippet)
        }
      }

      records[sessionId] = record
      publish()
    }
  }

  private func publish() {
    recordsSubject.send(sortedRecords())
  }

  private func sortedRecords() -> [ConversationRecord] {
    records.values.sorted { $0.updatedAt > $1.updatedAt }
  }

  private func hydratePersistedConversations(for agent: AgentProfile) {
    records.removeAll()
    conversations.values.forEach { $0.unbindUI() }
    conversations.removeAll()
    subscriptions.values.forEach { $0.cancel() }
    subscriptions.removeAll()

    guard let runtime, let repo = runtime.conversationRepository else {
      publish()
      return
    }

    Task { @MainActor in
      do {
        try await repo.ensureAgent(id: agent.id, name: agent.name)
        let stored = try await repo.fetchConversations(agentId: agent.id)
        
        var index = 1
        for item in stored {
          let record = ConversationRecord(
            sessionId: item.sessionId,
            agentId: agent.id,
            agentName: agent.name,
            title: item.agentName ?? "Session \(index)",
            lastMessagePreview: item.lastMessagePreview,
            createdAt: item.lastActivity ?? Date(),
            updatedAt: item.lastActivity ?? Date(),
            connection: connectionMode
          )
          records[record.sessionId] = record
          observeMessages(for: record.sessionId)
          index += 1
        }
        
        nextSessionIndex = max(index, 1)
        publish()
      } catch {
        print("[ConversationManager] Failed to hydrate conversations: \(error)")
        publish()
      }
    }
  }
}
