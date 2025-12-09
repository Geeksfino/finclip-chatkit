package com.finclip.chatkit.examples.conversation

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.Button
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.finclip.chatkit.ChatKitConversationListConfiguration
import com.finclip.chatkit.ChatKitCoordinator
import com.finclip.chatkit.examples.MainActivity
import com.finclip.chatkit.examples.R
import com.finclip.chatkit.examples.settings.ChatKitHelper
import com.finclip.chatkit.model.ConversationRecord
import com.finclip.chatkit.ui.ChatFragment
import com.finclip.chatkit.ui.ConversationListFragment
import com.finclip.chatkit.ui.HistoricalMessagesFragment
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import java.util.UUID

class ConversationManagementActivity : AppCompatActivity() {

    private val agentId = UUID.fromString("00000000-0000-0000-0000-000000000001")
    private lateinit var coordinator: ChatKitCoordinator

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_conversation_management)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.subtitle = ChatKitHelper.getStatusDescription()

        initChatKit()
        setupUI()
    }

    private fun initChatKit() {
        coordinator = ChatKitHelper.createCoordinator(this)
    }

    private fun setupUI() {
        findViewById<Button>(R.id.btnNewConversation).setOnClickListener {
            createNewConversation()
        }

        findViewById<Button>(R.id.btnShowList).setOnClickListener {
            showConversationList()
        }

        findViewById<Button>(R.id.btnSearchConversations).setOnClickListener {
            showSearchDialog()
        }

        findViewById<Button>(R.id.btnObserveRecords).setOnClickListener {
            observeRecords()
        }

        findViewById<Button>(R.id.btnClearAll).setOnClickListener {
            clearAllConversations()
        }
    }

    private fun createNewConversation() {
        lifecycleScope.launch {
            try {
                val (record, _) = coordinator.startConversation(
                    agentId = agentId,
                    title = "Chat ${System.currentTimeMillis() % 1000}"
                )

                val fragment = ChatFragment.newInstance(record.id)
                supportFragmentManager.beginTransaction()
                    .replace(R.id.fragmentContainer, fragment)
                    .addToBackStack(null)
                    .commit()

                Toast.makeText(this@ConversationManagementActivity, 
                    "Created: ${record.title}", Toast.LENGTH_SHORT).show()

            } catch (e: Exception) {
                Toast.makeText(this@ConversationManagementActivity, 
                    "Error: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun showConversationList() {
        val config = ChatKitConversationListConfiguration(
            headerTitle = "My Conversations",
            showSearchBar = true,
            showNewButton = true,
            enableSwipeToDelete = true,
            enableLongPress = true
        )

        val fragment = ConversationListFragment.newInstance(coordinator, config)
        
        fragment.setOnConversationSelectedListener { record ->
            openConversation(record)
        }
        
        fragment.setOnNewConversationClickListener {
            createNewConversation()
        }

        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .addToBackStack(null)
            .commit()
    }

    private fun openConversation(record: ConversationRecord) {
        val fragment = ChatFragment.newInstance(record.id)
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .addToBackStack(null)
            .commit()
    }

    private fun showSearchDialog() {
        val input = android.widget.EditText(this)
        input.hint = "Enter search query"

        AlertDialog.Builder(this)
            .setTitle("Search Conversations")
            .setView(input)
            .setPositiveButton("Search") { _, _ ->
                val query = input.text.toString()
                searchConversations(query)
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun searchConversations(query: String) {
        lifecycleScope.launch {
            try {
                val results = coordinator.conversationManager.searchConversations(query)
                Toast.makeText(this@ConversationManagementActivity,
                    "Found ${results.size} conversations", Toast.LENGTH_SHORT).show()

                if (results.isNotEmpty()) {
                    val record = coordinator.record(results.first())
                    record?.let { showHistoricalMessages(it.id) }
                }
            } catch (e: Exception) {
                Toast.makeText(this@ConversationManagementActivity,
                    "Search error: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun showHistoricalMessages(sessionId: UUID) {
        val fragment = HistoricalMessagesFragment.newInstance(sessionId)
        fragment.setOnOpenFullChatListener { id ->
            val chatFragment = ChatFragment.newInstance(id)
            supportFragmentManager.beginTransaction()
                .replace(R.id.fragmentContainer, chatFragment)
                .addToBackStack(null)
                .commit()
        }

        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .addToBackStack(null)
            .commit()
    }

    private fun observeRecords() {
        lifecycleScope.launch {
            coordinator.records.collectLatest { records ->
                Toast.makeText(this@ConversationManagementActivity,
                    "Total conversations: ${records.size}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun clearAllConversations() {
        AlertDialog.Builder(this)
            .setTitle("Clear All")
            .setMessage("Delete all conversations?")
            .setPositiveButton("Delete") { _, _ ->
                val conversations = coordinator.allConversations()
                conversations.forEach { record ->
                    coordinator.deleteConversation(record.id)
                }
                Toast.makeText(this, "All conversations deleted", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton("Cancel", null)
            .show()
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
