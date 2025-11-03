import Foundation

struct ConversationRecord: Equatable {
  let sessionId: UUID
  var agentId: UUID
  var agentName: String
  var title: String
  var lastMessagePreview: String?
  var createdAt: Date
  var updatedAt: Date
  let connection: ConnectionMode

  var lastUpdatedDescription: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: updatedAt, relativeTo: Date())
  }

  func updatingLastMessage(_ text: String?) -> ConversationRecord {
    ConversationRecord(
      sessionId: sessionId,
      agentId: agentId,
      agentName: agentName,
      title: title,
      lastMessagePreview: text,
      createdAt: createdAt,
      updatedAt: Date(),
      connection: connection
    )
  }

  func renaming(to newTitle: String) -> ConversationRecord {
    ConversationRecord(
      sessionId: sessionId,
      agentId: agentId,
      agentName: agentName,
      title: newTitle,
      lastMessagePreview: lastMessagePreview,
      createdAt: createdAt,
      updatedAt: Date(),
      connection: connection
    )
  }
}
