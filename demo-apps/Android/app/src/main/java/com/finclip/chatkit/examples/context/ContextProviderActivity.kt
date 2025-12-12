package com.finclip.chatkit.examples.context

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.finclip.chatkit.ChatKit
import com.finclip.chatkit.ChatKitConfiguration
import com.finclip.chatkit.ChatKitCoordinator
import com.finclip.chatkit.context.ContextAugmentationConfig
import com.finclip.chatkit.context.ContextAugmenter
import com.finclip.chatkit.context.ConversationContextItem
import com.finclip.chatkit.error.ChatKitError
import com.finclip.chatkit.error.ChatKitErrorHandler
import com.finclip.chatkit.examples.MainActivity
import com.finclip.chatkit.examples.R
import com.finclip.chatkit.examples.settings.ChatKitHelper
import com.finclip.chatkit.model.ConversationRecord
import com.finclip.chatkit.runtime.Conversation
import com.finclip.convoui.Listeners.FinConvoChatViewDelegate
import com.finclip.convoui.Models.Bridge.FinConvoMCPUIAction
import com.finclip.convoui.Models.Bridge.FinConvoOpenAIAction
import com.finclip.convoui.Models.Core.FinConvoMessageModel
import com.finclip.convoui.Models.Messages.FinConvoMarkdownMessageModel
import com.finclip.convoui.Models.Messages.FinConvoSendMessage
import com.finclip.convoui.Models.Messages.FinConvoSentMessageModel
import com.finclip.convoui.Models.PromptStarter.FinConvoPromptStarter
import com.finclip.convoui.Public.Composer.FinConvoAgent
import com.finclip.convoui.Public.Composer.FinConvoComposerTool
import com.finclip.convoui.Public.ConvoUIChatView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.Date
import java.util.UUID

/**
 * Context Provider 示例 - 演示上下文增强功能
 * 
 * 这个示例展示如何在发送消息时自动附加设备和网络状态信息，
 * 让 AI 更好地理解用户的使用场景。
 */
class ContextProviderActivity : AppCompatActivity(), FinConvoChatViewDelegate {

    private val TAG = "ContextProviderActivity"
    private val agentId = UUID.fromString("00000000-0000-0000-0000-000000000001")

    private lateinit var chatView: ConvoUIChatView
    
    // Track messages for ConvoUIChatView (since we can't access ViewModel directly)
    private val messageMap = mutableMapOf<String, FinConvoMessageModel>()
    private lateinit var promptContainer: LinearLayout
    private lateinit var scrollPrompts: ScrollView

    private var coordinator: ChatKitCoordinator? = null
    private var conversation: Conversation? = null
    private var conversationRecord: ConversationRecord? = null
    private var isProcessingMessage = false

    // 上下文增强器
    private val augmentationConfig = ContextAugmentationConfig(
        enabled = true,
        placement = ContextAugmentationConfig.Placement.BEFORE,
        maxContexts = 3,
        perItemLimit = 500,
        totalLimit = 1200
    )
    private val augmenter = ContextAugmenter(augmentationConfig)

    // Track displayed content length for delta updates
    private val displayedContentLengthMap = mutableMapOf<String, Int>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_context_provider)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.title = "Context Providers"
        supportActionBar?.subtitle = "消息将包含设备/网络状态"

        initViews()
        initChatKit()
    }

    private fun initViews() {
        chatView = findViewById(R.id.chatView)
        promptContainer = findViewById(R.id.chipGroupPrompts)
        scrollPrompts = findViewById(R.id.scrollPromptStarters)

        chatView.delegate = this

        // 添加提示 starters
        val starters = listOf(
            Pair("What's my device status?", "查询设备状态"),
            Pair("How's my network?", "查询网络状态"),
            Pair("Tell me about my context", "了解我的上下文")
        )

        starters.forEach { pair ->
            val title = pair.first
            val subtitle = pair.second
            val starterView = LayoutInflater.from(this)
                .inflate(com.finclip.chatkit.R.layout.item_prompt_starter, promptContainer, false)

            val titleView = starterView.findViewById<TextView>(com.finclip.chatkit.R.id.textTitle)
            val subtitleView = starterView.findViewById<TextView>(com.finclip.chatkit.R.id.textSubtitle)

            titleView.text = title
            subtitleView.text = subtitle
            subtitleView.visibility = View.VISIBLE

            starterView.setOnClickListener {
                processUserMessage(title)
            }
            promptContainer.addView(starterView)
        }
    }

    private fun initChatKit() {
        val config = ChatKitConfiguration(
            showWelcomeMessage = true,
            welcomeMessage = "🔧 上下文增强已启用！\n\n发送任何消息，我会自动附加你的设备状态和网络信息。"
        )

        coordinator = ChatKitHelper.createCoordinator(this, config)

        lifecycleScope.launch {
            try {
                val result = coordinator!!.startConversation(
                    agentId = agentId,
                    title = "Context Chat"
                )
                conversationRecord = result.first
                conversation = ChatKit.conversationManager.conversation(result.first.id)

                // 显示欢迎消息
                showWelcomeMessage(config)

                // 观察消息流
                observeMessages()

                // 显示当前上下文信息
                showCurrentContext()

            } catch (e: Exception) {
                Toast.makeText(this@ContextProviderActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private suspend fun showWelcomeMessage(config: ChatKitConfiguration) {
        val welcomeText = config.welcomeMessage ?: return
        val welcomeModel = FinConvoMarkdownMessageModel(
            _messageId = "welcome-${conversationRecord?.id}",
            _timestamp = Date(),
            isLoading = false,
        ).apply {
            setContent(welcomeText, this@ContextProviderActivity)
        }
        // 使用 ConvoUIChatView API
        chatView.displayMessage(welcomeModel)
        messageMap[welcomeModel.messageId] = welcomeModel
        withContext(Dispatchers.Main) {
            scrollPrompts.visibility = View.VISIBLE
            chatView.visibility = View.VISIBLE
        }
    }

    /**
     * 显示当前上下文信息
     */
    private fun showCurrentContext() {
        val contextItems = collectContextItems()
        val contextInfo = buildString {
            appendLine("📱 当前上下文信息:")
            contextItems.forEach { item ->
                appendLine("• ${item.displayName}: ${item.localizedDescription}")
            }
        }
        Toast.makeText(this, contextInfo, Toast.LENGTH_LONG).show()
        Log.d(TAG, contextInfo)
    }

    /**
     * 收集设备和网络上下文
     */
    private fun collectContextItems(): List<ConversationContextItem> {
        return listOf(
            getDeviceStateContext(),
            getNetworkStatusContext()
        )
    }

    /**
     * 获取设备状态上下文
     */
    private fun getDeviceStateContext(): ConversationContextItem {
        val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { ifilter ->
            registerReceiver(null, ifilter)
        }
        val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryPct = if (level >= 0 && scale > 0) {
            (level * 100 / scale.toFloat()).toInt()
        } else {
            -1
        }

        val isCharging = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            ?.let { it == BatteryManager.BATTERY_STATUS_CHARGING || it == BatteryManager.BATTERY_STATUS_FULL }
            ?: false

        val description = buildString {
            append("Android ${Build.VERSION.RELEASE}")
            append(", Battery: $batteryPct%")
            if (isCharging) append(" (Charging)")
            append(", Device: ${Build.MANUFACTURER} ${Build.MODEL}")
        }

        return ConversationContextItem(
            type = "device_state",
                displayName = "Device State",
            localizedDescription = description,
        )
    }

    /**
     * 获取网络状态上下文
     */
    private fun getNetworkStatusContext(): ConversationContextItem {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork
        val capabilities = cm.getNetworkCapabilities(network)

        val isConnected = capabilities != null
        val isWifi = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
        val isCellular = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true

        val description = when {
            !isConnected -> "Disconnected"
            isWifi -> "Connected via WiFi"
            isCellular -> "Connected via Cellular"
            else -> "Connected (Unknown type)"
        }

        return ConversationContextItem(
                type = "network_status",
                displayName = "Network",
            localizedDescription = description,
        )
    }

    /**
     * 处理用户消息 - 增强后发送
     */
    private fun processUserMessage(text: String) {
        val trimmedText = text.trim()
        if (trimmedText.isEmpty() || isProcessingMessage) return

        isProcessingMessage = true

        lifecycleScope.launch {
            try {
                // 1. 收集上下文
                val contextItems = collectContextItems()

                // 2. 增强消息
                val augmentedMessage = augmenter.augment(trimmedText, contextItems)

                // 3. 显示日志，让用户知道发送的是增强后的消息
                Log.d(TAG, "=== 发送增强消息 ===")
                Log.d(TAG, "原始消息: $trimmedText")
                Log.d(TAG, "增强后消息:\n$augmentedMessage")
                Log.d(TAG, "=====================")

                // 4. 发送增强后的消息
                conversation?.sendMessage(augmentedMessage)

                // 5. Toast 提示
                withContext(Dispatchers.Main) {
                    Toast.makeText(
                        this@ContextProviderActivity,
                        "✅ 已发送增强消息 (含 ${contextItems.size} 个上下文)",
                        Toast.LENGTH_SHORT
                    ).show()
                }

            } catch (e: Exception) {
                ChatKitErrorHandler.handle(ChatKitError.from(e), this@ContextProviderActivity)
            } finally {
                delay(500)
                isProcessingMessage = false
            }
        }
    }

    /**
     * 观察消息流更新 UI
     */
    private fun observeMessages() {
        lifecycleScope.launch {
            conversation?.messages()?.collect { messages ->
                val sortedMessages = messages.sortedBy { it.timestamp }

                sortedMessages.forEach { msg ->
                    val msgId = msg.id.toString()
                    val existingModel = messageMap[msgId]

                    if (existingModel == null) {
                        // 新消息
                        val model = if (msg.isUser) {
                            FinConvoSentMessageModel(
                                _messageId = msgId,
                                text = msg.content,
                                _timestamp = msg.timestamp,
                            )
                        } else {
                            FinConvoMarkdownMessageModel(
                                _messageId = msgId,
                                _timestamp = msg.timestamp,
                                isLoading = false,
                            ).apply {
                                setContent(msg.content, this@ContextProviderActivity)
                            }
                        }

                        if (!msg.isUser) {
                            displayedContentLengthMap[msgId] = msg.content.length
                        }
                        
                        // 使用 ConvoUIChatView API
                        chatView.displayMessage(model)
                        messageMap[msgId] = model
                    } else if (!msg.isUser && existingModel is FinConvoMarkdownMessageModel) {
                        // 更新现有消息（流式响应）
                        val recordedLength = displayedContentLengthMap[msgId] ?: 0
                        val fullText = msg.content

                        if (fullText.length > recordedLength) {
                            // Create new message with updated content
                            val updatedModel = FinConvoMarkdownMessageModel(
                                _messageId = msgId,
                                _timestamp = existingModel.timestamp ?: Date(),
                                isLoading = true  // Still streaming
                            ).apply {
                                if (recordedLength == 0 && fullText.isNotEmpty()) {
                                    setContent(fullText, this@ContextProviderActivity)
                                } else {
                                    val currentContent = existingModel.markdownContent
                                    setContent(currentContent, this@ContextProviderActivity)
                                    val delta = fullText.substring(recordedLength)
                                    appendDelta(delta)
                                }
                            }
                            
                            displayedContentLengthMap[msgId] = fullText.length
                            
                            // 使用 ConvoUIChatView API 替换消息
                            chatView.replaceOrUpdateMessage(msgId, updatedModel)
                            messageMap[msgId] = updatedModel
                        } else if (fullText.isEmpty() && recordedLength == 0) {
                            // Message is still loading but no content yet
                            val updatedModel = FinConvoMarkdownMessageModel(
                                _messageId = msgId,
                                _timestamp = existingModel.timestamp ?: Date(),
                                isLoading = true
                            )
                            chatView.replaceOrUpdateMessage(msgId, updatedModel)
                            messageMap[msgId] = updatedModel
                        } else if (fullText.isNotEmpty() && existingModel.isLoading) {
                            // Message completed - mark as not loading
                            val updatedModel = FinConvoMarkdownMessageModel(
                                _messageId = msgId,
                                _timestamp = existingModel.timestamp ?: Date(),
                                isLoading = false
                            ).apply {
                                setContent(fullText, this@ContextProviderActivity)
                            }
                            chatView.replaceOrUpdateMessage(msgId, updatedModel)
                            messageMap[msgId] = updatedModel
                        }
                    }
                }

                if (sortedMessages.isNotEmpty()) {
                    withContext(Dispatchers.Main) {
                        scrollPrompts.visibility = View.GONE
                        chatView.visibility = View.VISIBLE
                    }
                }
            }
        }
    }

    // FinConvoChatViewDelegate 实现

    override fun onUserMessage(message: FinConvoSendMessage) {
        processUserMessage(message.messageText ?: "")
    }

    override fun onUserMessageWithSerializedData(
        message: FinConvoSendMessage,
        contextItemsData: List<Map<String, Any>>?,
        selectedAgent: FinConvoAgent?,
        selectedToolData: Map<String, Any>?,
    ) {
        processUserMessage(message.messageText ?: "")
    }

    override fun onMCPUIAction(messageId: String, action: FinConvoMCPUIAction) {}
    override fun onOpenAIAction(messageId: String, action: FinConvoOpenAIAction, completion: (Any) -> Unit) {}
    override fun onUIComponentAction(messageId: String, actionName: String, actionData: Map<String, Any>) {}
    override fun onLoadMoreHistory(messageId: String?, timestamp: Date?, completion: (List<FinConvoMessageModel>, Boolean) -> Unit) {
        completion(emptyList(), false)
    }
    override fun onComposerToolSelected(tool: FinConvoComposerTool) {}
    override fun chatViewDidMoveToWindow(isVisible: Boolean) {}
    override fun chatViewDidRequestCancelCurrentRun() {}
    override fun chatViewDidConsentToProposal(proposalId: String) {}
    override fun chatViewDidRejectProposal(proposalId: String) {}
    override fun chatViewPromptStarterShown(starters: List<FinConvoPromptStarter>) {}
    override fun chatViewPromptStarterTapped(starter: FinConvoPromptStarter) {}

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_example, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_home -> {
                val intent = Intent(this, MainActivity::class.java)
                intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                startActivity(intent)
                finish()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }
}
