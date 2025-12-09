package com.finclip.chatkit.examples.mock

import com.finclip.chatkit.model.Agent
import com.finclip.chatkit.model.ConversationItem
import com.finclip.chatkit.model.Message
import com.finclip.chatkit.runtime.Conversation
import com.finclip.chatkit.runtime.ConversationRepository
import com.finclip.chatkit.runtime.NeuronRuntime
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Mock implementation of NeuronRuntime for offline testing.
 * Provides simulated AI responses without requiring a real server.
 */
class MockRuntime : NeuronRuntime {
    private val conversations = ConcurrentHashMap<UUID, MockConversation>()
    private val messageStore = ConcurrentHashMap<UUID, MutableList<Message>>()
    private val messageFlows = ConcurrentHashMap<UUID, MutableStateFlow<List<Message>>>()

    // Provide a mock repository so ChatKitConversationManager can work
    override val conversationRepository: ConversationRepository = MockConversationRepository()

    override fun openConversation(sessionId: UUID, agentId: UUID): Conversation {
        val conversation = MockConversation(sessionId, agentId, this)
        conversations[sessionId] = conversation
        messageStore.getOrPut(sessionId) { mutableListOf() }
        messageFlows.getOrPut(sessionId) { MutableStateFlow(emptyList()) }
        return conversation
    }

    override fun resumeConversation(sessionId: UUID, agentId: UUID): Conversation {
        return conversations[sessionId] ?: openConversation(sessionId, agentId)
    }

    override fun messagesFlow(sessionId: UUID): Flow<List<Message>> {
        return messageFlows.getOrPut(sessionId) { MutableStateFlow(emptyList()) }.asStateFlow()
    }

    override suspend fun messagesSnapshot(sessionId: UUID, limit: Int): List<Message> {
        return messageStore[sessionId]?.takeLast(limit) ?: emptyList()
    }

    override suspend fun searchMessages(containing: String): List<UUID> {
        return messageStore.entries
            .filter { (_, messages) -> messages.any { it.content.contains(containing, ignoreCase = true) } }
            .map { it.key }
    }

    override suspend fun clearMessages(sessionId: UUID) {
        messageStore[sessionId]?.clear()
        messageFlows[sessionId]?.value = emptyList()
    }

    internal fun addMessage(sessionId: UUID, message: Message) {
        val messages = messageStore.getOrPut(sessionId) { mutableListOf() }
        messages.add(message)
        messageFlows.getOrPut(sessionId) { MutableStateFlow(emptyList()) }.value = messages.toList()
    }

    internal fun updateMessage(sessionId: UUID, messageId: UUID, newContent: String) {
        val messages = messageStore[sessionId] ?: return
        val index = messages.indexOfFirst { it.id == messageId }
        if (index >= 0) {
            messages[index] = messages[index].copy(content = newContent)
            messageFlows[sessionId]?.value = messages.toList()
        }
    }

    internal fun getMessages(sessionId: UUID): List<Message> {
        return messageStore[sessionId]?.toList() ?: emptyList()
    }
}

/**
 * Mock implementation of ConversationRepository for offline storage.
 */
class MockConversationRepository : ConversationRepository {
    private val agents = ConcurrentHashMap<UUID, Agent>()
    private val conversationItems = ConcurrentHashMap<UUID, ConversationItem>()

    override suspend fun ensureAgent(id: UUID, name: String) {
        agents[id] = Agent(id = id, name = name)
    }

    override suspend fun ensureConversation(sessionId: UUID, agentId: UUID, deviceId: String) {
        conversationItems[sessionId] = ConversationItem(
            sessionId = sessionId,
            agentId = agentId,
            title = "",
            lastMessagePreview = null,
            lastActivity = Date()
        )
    }

    override suspend fun updateTitle(title: String, forSessionId: UUID) {
        conversationItems[forSessionId]?.let {
            conversationItems[forSessionId] = it.copy(title = title)
        }
    }

    override suspend fun deleteConversation(sessionId: UUID) {
        conversationItems.remove(sessionId)
    }

    override suspend fun fetchAgents(): List<Agent> {
        return agents.values.toList()
    }

    override suspend fun fetchConversations(agentId: UUID): List<ConversationItem> {
        return conversationItems.values.filter { it.agentId == agentId }
    }
}

class MockConversation(
    override val sessionId: UUID,
    override val agentId: UUID,
    private val runtime: MockRuntime
) : Conversation {

    private val mockResponses = listOf(
        "你好！我是 Mock AI 助手。有什么我可以帮助你的吗？",
        "这是一个很好的问题！让我来为你解答...\n\nMock 模式下，我会返回预设的回复来帮助你测试应用功能。",
        "我理解了。在 Mock 模式下，所有的回复都是预设的，不会连接真实的服务器。\n\n这对于:\n- 离线开发\n- UI 测试\n- 功能演示\n\n都非常有用！",
        "当然可以！这是一段示例代码：\n\n```kotlin\nfun greet(name: String): String {\n    return \"Hello, \$name!\"\n}\n```\n\n希望这对你有帮助！",
        "Mock AI 正在处理你的请求...\n\n✅ 任务已完成！\n\n这是模拟的成功响应。",
        "这是一个有趣的话题！让我分享一些想法...\n\n1. 首先，Mock 模式非常适合开发测试\n2. 其次，它不需要网络连接\n3. 最后，响应速度很快\n\n还有其他问题吗？"
    )

    override suspend fun sendMessage(text: String) {
        // Add user message
        val userMessage = Message(
            id = UUID.randomUUID(),
            conversationId = sessionId,
            content = text,
            isUser = true,
            timestamp = Date()
        )
        runtime.addMessage(sessionId, userMessage)

        // Generate response and add it after a delay
        val fullResponse = generateMockResponse(text)
        
        // Use coroutine to simulate delay
        kotlinx.coroutines.withContext(Dispatchers.IO) {
            delay(800) // Simulate thinking time
        }

        // Add AI response message
        val responseMessage = Message(
            id = UUID.randomUUID(),
            conversationId = sessionId,
            content = fullResponse,
            isUser = false,
            timestamp = Date()
        )
        runtime.addMessage(sessionId, responseMessage)
    }

    private fun generateMockResponse(userInput: String): String {
        return when {
            userInput.contains("你好", ignoreCase = true) ||
            userInput.contains("hello", ignoreCase = true) ||
            userInput.contains("hi", ignoreCase = true) ->
                mockResponses[0]

            userInput.contains("代码", ignoreCase = true) ||
            userInput.contains("code", ignoreCase = true) ||
            userInput.contains("编程", ignoreCase = true) ->
                mockResponses[3]

            userInput.contains("帮助", ignoreCase = true) ||
            userInput.contains("help", ignoreCase = true) ->
                mockResponses[1]

            userInput.contains("mock", ignoreCase = true) ||
            userInput.contains("模拟", ignoreCase = true) ->
                mockResponses[2]

            else -> mockResponses.random()
        }
    }

    override fun messages(): Flow<List<Message>> = runtime.messagesFlow(sessionId)

    override fun unbindUI() {}
}
