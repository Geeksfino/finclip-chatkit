import SwiftUI
import ChatKit

@main
struct MyChatGPTApp: App {
  @State private var sessionId = UUID().uuidString

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ConversationView(sessionId: sessionId)
          .navigationTitle("MyChatGPT")
      }
    }
  }
}

struct ConversationView: View {
  let sessionId: String

  var body: some View {
    ChatKitView(sessionId: sessionId)
      .applyDefaultTheme()
      .padding()
      .task {
        await bootstrapConversation()
      }
  }

  private func bootstrapConversation() async {
    let welcome = ChatMessage.user(text: "Hello! How can ChatKit assist you today?")
    await ChatKit.shared.enqueue(message: welcome, for: sessionId)
  }
}
