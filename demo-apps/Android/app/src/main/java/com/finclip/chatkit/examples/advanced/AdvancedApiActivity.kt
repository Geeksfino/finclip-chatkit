package com.finclip.chatkit.examples.advanced

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.finclip.chatkit.ChatKit
import com.finclip.chatkit.ChatKitConfiguration
import com.finclip.chatkit.ChatKitConversationListConfiguration
import com.finclip.chatkit.ChatKitCoordinator
import com.finclip.chatkit.ChatKitPromptStarterFactory
import com.finclip.chatkit.ConnectionMode
import com.finclip.chatkit.ConnectionStatusProvider
import com.finclip.chatkit.ConversationTitleProvider
import com.finclip.chatkit.DividerConfig
import com.finclip.chatkit.error.ChatKitErrorHandler
import com.finclip.chatkit.error.ErrorHandler
import com.finclip.chatkit.examples.MainActivity
import com.finclip.chatkit.examples.R
import com.finclip.chatkit.examples.settings.AppSettings
import com.finclip.chatkit.examples.settings.ChatKitHelper
import com.finclip.chatkit.model.Message
import com.finclip.chatkit.ui.ChatFragment
import com.finclip.chatkit.ui.ConversationListFragment
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.UUID

class AdvancedApiActivity : AppCompatActivity() {

    private val agentId = UUID.fromString("00000000-0000-0000-0000-000000000001")
    private lateinit var coordinator: ChatKitCoordinator

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_advanced_api)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.subtitle = ChatKitHelper.getStatusDescription()

        setupUI()
    }

    private fun setupUI() {
        findViewById<android.widget.Button>(R.id.btnFrameworkInfo).setOnClickListener {
            showFrameworkInfo()
        }

        findViewById<android.widget.Button>(R.id.btnCustomTitleProvider).setOnClickListener {
            demoCustomTitleProvider()
        }

        findViewById<android.widget.Button>(R.id.btnCustomConnectionProvider).setOnClickListener {
            demoCustomConnectionProvider()
        }

        findViewById<android.widget.Button>(R.id.btnConnectionMode).setOnClickListener {
            demoConnectionMode()
        }

        findViewById<android.widget.Button>(R.id.btnPromptStarterFactory).setOnClickListener {
            demoPromptStarterFactory()
        }

        findViewById<android.widget.Button>(R.id.btnMinimalConfig).setOnClickListener {
            demoMinimalConfig()
        }

        findViewById<android.widget.Button>(R.id.btnCompactListConfig).setOnClickListener {
            demoCompactListConfig()
        }

        findViewById<android.widget.Button>(R.id.btnCustomErrorHandler).setOnClickListener {
            demoCustomErrorHandler()
        }

        findViewById<android.widget.Button>(R.id.btnClearMessages).setOnClickListener {
            demoClearMessages()
        }

        findViewById<android.widget.Button>(R.id.btnLowLevelApi).setOnClickListener {
            demoLowLevelApi()
        }
    }

    private fun showFrameworkInfo() {
        val info = ChatKit.frameworkInfo()
        val message = info.entries.joinToString("\n") { "${it.key}: ${it.value}" }
        AlertDialog.Builder(this)
            .setTitle("Framework Info")
            .setMessage("Version: ${ChatKit.VERSION}\n\n$message")
            .setPositiveButton("OK", null)
            .show()
    }

    private fun demoCustomTitleProvider() {
        val customTitleProvider = object : ConversationTitleProvider {
            override suspend fun shouldGenerateTitle(
                sessionId: UUID,
                messageCount: Int,
                currentTitle: String?
            ): Boolean {
                return messageCount >= 2 && currentTitle.isNullOrEmpty()
            }

            override suspend fun generateTitle(messages: List<Message>): String? {
                val firstUserMessage = messages.firstOrNull { it.isUser }
                return firstUserMessage?.content?.take(20)?.let { "$it..." }
            }
        }

        coordinator = ChatKit.createCoordinator(
            context = this,
            serverURL = "wss://example.com/chat",
            userId = "user-${System.currentTimeMillis()}",
            titleProvider = customTitleProvider
        )

        Toast.makeText(this, "Custom TitleProvider set", Toast.LENGTH_SHORT).show()
        startConversation()
    }

    private fun demoCustomConnectionProvider() {
        val customConnectionProvider = object : ConnectionStatusProvider {
            private val _status = MutableStateFlow("Custom: Connecting...")
            override val connectionStatus: StateFlow<String> = _status

            override fun startMonitoring() {
                _status.value = "Custom: Connected"
            }

            override fun stopMonitoring() {
                _status.value = "Custom: Disconnected"
            }
        }

        coordinator = ChatKit.createCoordinator(
            context = this,
            serverURL = "wss://example.com/chat",
            userId = "user-${System.currentTimeMillis()}",
            connectionStatusProvider = customConnectionProvider
        )

        Toast.makeText(this, "Custom ConnectionStatusProvider set", Toast.LENGTH_SHORT).show()

        lifecycleScope.launch {
            coordinator.connectionStatus.collect { status ->
                supportActionBar?.subtitle = status
            }
        }
    }

    private fun demoConnectionMode() {
        if (!::coordinator.isInitialized) {
            initDefaultCoordinator()
        }

        // Current connection URL for reference
        val currentURL = coordinator.serverURL

        val options = arrayOf(
            "Remote (wss://prod.example.com)",
            "Remote (wss://staging.example.com)",
            "Fixture Mode"
        )

        AlertDialog.Builder(this)
            .setTitle("Connection Mode\nCurrent: $currentURL")
            .setItems(options) { _, which ->
                val newMode = when (which) {
                    0 -> ConnectionMode.Remote("wss://prod.example.com")
                    1 -> ConnectionMode.Remote("wss://staging.example.com")
                    else -> ConnectionMode.Fixture
                }
                coordinator.updateConnectionMode(newMode)
                Toast.makeText(this, "Mode: ${newMode.serverURL}", Toast.LENGTH_SHORT).show()
            }
            .show()
    }

    private fun demoPromptStarterFactory() {
        val defaultStarters = ChatKitPromptStarterFactory.createDefaultStarters()
        val exampleStarters = ChatKitPromptStarterFactory.createExampleStarters()

        val message = buildString {
            appendLine("Default Starters (${defaultStarters.size}):")
            defaultStarters.forEach { appendLine("  - ${it.title}") }
            appendLine()
            appendLine("Example Starters (${exampleStarters.size}):")
            exampleStarters.forEach { appendLine("  - ${it.title}") }
        }

        AlertDialog.Builder(this)
            .setTitle("Prompt Starter Factory")
            .setMessage(message)
            .setPositiveButton("OK", null)
            .show()
    }

    private fun demoMinimalConfig() {
        val minimalChatConfig = ChatKitConfiguration.minimal()
        val minimalListConfig = ChatKitConversationListConfiguration.minimal()

        coordinator = ChatKit.createCoordinator(
            context = this,
            serverURL = "wss://example.com/chat",
            userId = "user-${System.currentTimeMillis()}",
            chatKitConfiguration = minimalChatConfig
        )

        val fragment = ConversationListFragment.newInstance(coordinator, minimalListConfig)
        fragment.setOnConversationSelectedListener { record ->
            val chatFragment = ChatFragment.newInstance(record.id)
            supportFragmentManager.beginTransaction()
                .replace(R.id.fragmentContainer, chatFragment)
                .addToBackStack(null)
                .commit()
        }

        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .addToBackStack(null)
            .commit()

        Toast.makeText(this, "Minimal config applied", Toast.LENGTH_SHORT).show()
    }

    private fun demoCompactListConfig() {
        if (!::coordinator.isInitialized) {
            initDefaultCoordinator()
        }

        // Demo: using custom divider config (compact() is also available)
        val customDividerConfig = ChatKitConversationListConfiguration(
            cellStyle = com.finclip.chatkit.CellStyle.CARD,
            dividerConfig = DividerConfig.FULL_WIDTH,
            rowHeightDp = 80
        )

        val fragment = ConversationListFragment.newInstance(coordinator, customDividerConfig)
        fragment.setOnConversationSelectedListener { record ->
            val chatFragment = ChatFragment.newInstance(record.id)
            supportFragmentManager.beginTransaction()
                .replace(R.id.fragmentContainer, chatFragment)
                .addToBackStack(null)
                .commit()
        }

        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .addToBackStack(null)
            .commit()

        Toast.makeText(this, "Card style with full-width divider", Toast.LENGTH_SHORT).show()
    }

    private fun demoCustomErrorHandler() {
        val previousHandler = ChatKitErrorHandler.getHandler()

        val customHandler = object : ErrorHandler {
            override fun handleError(
                error: com.finclip.chatkit.error.ChatKitError,
                context: android.content.Context?,
                showRecoveryAction: Boolean
            ) {
                AlertDialog.Builder(context ?: return)
                    .setTitle("Custom Error Handler")
                    .setMessage("Error: ${error.code}\n\n${error.userMessage}")
                    .setPositiveButton("OK", null)
                    .show()
            }

            override fun handleError(
                error: com.finclip.chatkit.error.ChatKitError,
                customMessage: String?,
                context: android.content.Context?,
                showRecoveryAction: Boolean
            ) {
                handleError(error, context, showRecoveryAction)
            }
        }

        ChatKitErrorHandler.setHandler(customHandler)
        Toast.makeText(this, "Custom ErrorHandler set", Toast.LENGTH_SHORT).show()

        ChatKitErrorHandler.handle(
            com.finclip.chatkit.error.ChatKitError.NetworkError.NoConnection,
            this
        )

        ChatKitErrorHandler.setHandler(previousHandler)
    }

    private fun demoClearMessages() {
        if (!::coordinator.isInitialized) {
            initDefaultCoordinator()
        }

        lifecycleScope.launch {
            try {
                val (record, _) = coordinator.startConversation(agentId, "Test Clear")
                Toast.makeText(this@AdvancedApiActivity, "Created: ${record.id}", Toast.LENGTH_SHORT).show()

                coordinator.clearMessages(record.id)
                Toast.makeText(this@AdvancedApiActivity, "Messages cleared", Toast.LENGTH_SHORT).show()

            } catch (e: Exception) {
                Toast.makeText(this@AdvancedApiActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun demoLowLevelApi() {
        if (AppSettings.useMock) {
            val mockRuntime = ChatKitHelper.getMockRuntime()
            val sessionId = UUID.randomUUID()
            val conversation = mockRuntime.openConversation(sessionId, agentId)

            lifecycleScope.launch {
                conversation.messages().collect { messages ->
                    Toast.makeText(
                        this@AdvancedApiActivity,
                        "Mock Runtime: ${messages.size} messages",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }

            Toast.makeText(this, "Mock Runtime created", Toast.LENGTH_SHORT).show()
            return
        }

        val runtime = ChatKit.createRuntime(
            context = this,
            serverURL = AppSettings.serverUrl,
            userId = AppSettings.userId
        )

        val sessionId = UUID.randomUUID()
        val conversation = runtime.openConversation(sessionId, agentId)

        lifecycleScope.launch {
            conversation.messages().collect { messages ->
                Toast.makeText(
                    this@AdvancedApiActivity,
                    "Low-level: ${messages.size} messages",
                    Toast.LENGTH_SHORT
                ).show()
            }
        }

        Toast.makeText(this, "Low-level Runtime created", Toast.LENGTH_SHORT).show()
    }

    private fun initDefaultCoordinator() {
        coordinator = ChatKitHelper.createCoordinator(this)
    }

    private fun startConversation() {
        lifecycleScope.launch {
            try {
                val (record, _) = coordinator.startConversation(agentId, "Advanced Demo")
                val fragment = ChatFragment.newInstance(record.id)
                supportFragmentManager.beginTransaction()
                    .replace(R.id.fragmentContainer, fragment)
                    .addToBackStack(null)
                    .commit()
            } catch (e: Exception) {
                Toast.makeText(this@AdvancedApiActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

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
        if (supportFragmentManager.backStackEntryCount > 0) {
            supportFragmentManager.popBackStack()
        } else {
            finish()
        }
        return true
    }
}
