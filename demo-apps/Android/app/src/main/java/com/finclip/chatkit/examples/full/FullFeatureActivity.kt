package com.finclip.chatkit.examples.full

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.finclip.chatkit.ChatKitConfiguration
import com.finclip.chatkit.ChatKitConversationListConfiguration
import com.finclip.chatkit.ChatKitCoordinator
import com.finclip.chatkit.CellStyle
import com.finclip.chatkit.ConversationTitleProvider
import com.finclip.chatkit.DefaultTitleProvider
import com.finclip.chatkit.PromptStarterBehaviorMode
import com.finclip.chatkit.StatusBannerStyle
import com.finclip.chatkit.error.ChatKitError
import com.finclip.chatkit.error.ChatKitErrorHandler
import com.finclip.chatkit.examples.MainActivity
import com.finclip.chatkit.examples.R
import com.finclip.chatkit.examples.settings.AppSettings
import com.finclip.chatkit.examples.settings.ChatKitHelper
import com.finclip.chatkit.logging.ChatKitLogger
import com.finclip.chatkit.logging.FileLogHandler
import com.finclip.chatkit.logging.LogLevel
import com.finclip.chatkit.model.ConversationRecord
import com.finclip.chatkit.ui.ChatFragment
import com.finclip.chatkit.ui.ConversationListFragment
import com.finclip.convoui.Models.PromptStarter.FinConvoPromptStarter
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import java.util.UUID

class FullFeatureActivity : AppCompatActivity() {

    private val agentId = UUID.fromString("00000000-0000-0000-0000-000000000001")
    private lateinit var coordinator: ChatKitCoordinator
    private var fileLogHandler: FileLogHandler? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_full_feature)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)

        setupLogging()
        initChatKit()
        setupUI()
        observeConnectionStatus()
    }

    private fun setupLogging() {
        ChatKitLogger.setMinLogLevel(LogLevel.DEBUG)

        fileLogHandler = FileLogHandler(
            context = this,
            logFileName = "chatkit_example.log",
            maxFileSize = 5 * 1024 * 1024,
            maxFiles = 3
        )
        ChatKitLogger.addHandler(fileLogHandler!!)

        ChatKitLogger.i(message = "FullFeatureActivity started")
    }

    private fun initChatKit() {
        val titleProvider = createTitleProvider()
        val config = createFullConfiguration()

        coordinator = ChatKitHelper.createCoordinator(this, config, titleProvider)

        ChatKitLogger.d(message = "ChatKit coordinator initialized (Mock: ${AppSettings.useMock})")
    }

    private fun createTitleProvider(): ConversationTitleProvider {
        return DefaultTitleProvider()
    }

    private fun createFullConfiguration(): ChatKitConfiguration {
        return ChatKitConfiguration(
            showWelcomeMessage = true,
            welcomeMessageProvider = { record ->
                "Welcome to ${record.title}! I'm ready to help."
            },
            promptStartersEnabled = true,
            promptStartersProvider = {
                listOf(
                    FinConvoPromptStarter("s1", "Quick question", "Ask anything", null, null),
                    FinConvoPromptStarter("s2", "Help me code", "Programming help", null, null),
                    FinConvoPromptStarter("s3", "Explain concept", "Learn something", null, null),
                    FinConvoPromptStarter("s4", "Creative writing", "Stories & content", null, null)
                )
            },
            promptStarterBehaviorMode = PromptStarterBehaviorMode.AUTO_HIDE,
            onPromptStarterSelected = { starter ->
                ChatKitLogger.d(message = "Starter selected: ${starter.title}")
                false
            },
            showStatusBanner = true,
            statusBannerStyle = StatusBannerStyle(
                height = 32,
                fontSize = 12f,
                textColor = Color.WHITE,
                connectedColor = Color.parseColor("#388E3C"),
                connectingColor = Color.parseColor("#FFA000"),
                reconnectingColor = Color.parseColor("#F57C00"),
                disconnectedColor = Color.parseColor("#D32F2F"),
                errorColor = Color.parseColor("#C62828")
            ),
            statusBannerAutoHide = true,
            statusBannerAutoHideDelay = 2000L,
            inputPlaceholder = "Type a message...",
            inputMaxLength = 4000,
            inputAllowsMultiline = true,
            paginationEnabled = true,
            paginationPageSize = 100
        )
    }

    private fun setupUI() {
        findViewById<android.widget.Button>(R.id.btnNewChat).setOnClickListener {
            startNewConversation()
        }

        findViewById<android.widget.Button>(R.id.btnShowList).setOnClickListener {
            showConversationList()
        }

        findViewById<android.widget.Button>(R.id.btnShowLogs).setOnClickListener {
            showLogs()
        }

        findViewById<android.widget.Button>(R.id.btnTestError).setOnClickListener {
            testErrorHandling()
        }
    }

    private fun observeConnectionStatus() {
        lifecycleScope.launch {
            coordinator.connectionStatus.collectLatest { status ->
                ChatKitLogger.d(message = "Connection status: $status")
                supportActionBar?.subtitle = status
            }
        }

        lifecycleScope.launch {
            coordinator.records.collectLatest { records ->
                ChatKitLogger.d(message = "Conversations count: ${records.size}")
            }
        }
    }

    private fun startNewConversation() {
        lifecycleScope.launch {
            try {
                val (record, _) = coordinator.startConversation(
                    agentId = agentId,
                    title = "Chat ${System.currentTimeMillis() % 10000}"
                )

                ChatKitLogger.i(message = "Created conversation: ${record.id}")
                openChat(record)

            } catch (e: Exception) {
                handleError(e)
            }
        }
    }

    private fun openChat(record: ConversationRecord) {
        val fragment = ChatFragment.newInstance(record.id)
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .addToBackStack("chat")
            .commit()
    }

    private fun showConversationList() {
        val listConfig = ChatKitConversationListConfiguration(
            searchPlaceholder = "Search chats...",
            headerTitle = "All Conversations",
            showHeader = true,
            showSearchBar = true,
            showNewButton = true,
            cellStyle = CellStyle.DEFAULT,
            enableSwipeToDelete = true,
            enableLongPress = true,
            searchEnabled = true,
            rowHeightDp = 72,
            emptyStateText = "No conversations yet",
            emptySearchResultText = "No results found",
            showMessagePreview = true,
            showTimestamp = true,
            showPinIndicator = true
        )

        val fragment = ConversationListFragment.newInstance(coordinator, listConfig)

        fragment.setOnConversationSelectedListener { record ->
            openChat(record)
        }

        fragment.setOnNewConversationClickListener {
            startNewConversation()
        }

        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .addToBackStack("list")
            .commit()
    }

    private fun showLogs() {
        val logPath = fileLogHandler?.getLogFilePath() ?: "No log file"
        AlertDialog.Builder(this)
            .setTitle("Log File")
            .setMessage("Log path: $logPath")
            .setPositiveButton("OK", null)
            .setNeutralButton("Clear Logs") { _, _ ->
                fileLogHandler?.clearLogs()
                Toast.makeText(this, "Logs cleared", Toast.LENGTH_SHORT).show()
            }
            .show()
    }

    private fun testErrorHandling() {
        val errors = listOf(
            ChatKitError.NetworkError.NoConnection,
            ChatKitError.NetworkError.Timeout,
            ChatKitError.ConversationError.RuntimeNotAttached,
            ChatKitError.ConversationError.StorageUnavailable
        )

        val errorNames = errors.map { it.code }

        AlertDialog.Builder(this)
            .setTitle("Test Error")
            .setItems(errorNames.toTypedArray()) { _, which ->
                val error = errors[which]
                ChatKitErrorHandler.handle(error, this)
            }
            .show()
    }

    private fun handleError(e: Exception) {
        val error = ChatKitError.from(e)
        ChatKitLogger.e(message = "Error: ${error.code}", throwable = e)
        ChatKitErrorHandler.handle(error, this)
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

    override fun onDestroy() {
        super.onDestroy()
        fileLogHandler?.let { ChatKitLogger.removeHandler(it) }
    }
}
