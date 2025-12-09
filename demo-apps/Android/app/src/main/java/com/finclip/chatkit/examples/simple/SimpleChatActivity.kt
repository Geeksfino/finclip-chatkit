package com.finclip.chatkit.examples.simple

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.finclip.chatkit.examples.MainActivity
import com.finclip.chatkit.examples.R
import com.finclip.chatkit.examples.settings.ChatKitHelper
import com.finclip.chatkit.ui.ChatFragment
import kotlinx.coroutines.launch
import java.util.UUID

class SimpleChatActivity : AppCompatActivity() {

    private val agentId = UUID.fromString("00000000-0000-0000-0000-000000000001")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_simple_chat)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.subtitle = ChatKitHelper.getStatusDescription()

        initChatKit()
    }

    private fun initChatKit() {
        // Both Mock and Server modes use the same ChatFragment (ConvoUI)
        // The difference is only in the data source (MockRuntime vs RealNeuronRuntime)
        val coordinator = ChatKitHelper.createCoordinator(this)

        lifecycleScope.launch {
            try {
                val (record, _) = coordinator.startConversation(
                    agentId = agentId,
                    title = "Simple Chat"
                )

                val fragment = ChatFragment.newInstance(record.id)
                supportFragmentManager.beginTransaction()
                    .replace(R.id.fragmentContainer, fragment)
                    .commit()

            } catch (e: Exception) {
                Toast.makeText(this@SimpleChatActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
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
        finish()
        return true
    }
}
