package com.finclip.chatkit.examples

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.Menu
import android.view.MenuItem
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.finclip.chatkit.examples.advanced.AdvancedApiActivity
import com.finclip.chatkit.examples.compose.ComposeExampleActivity
import com.finclip.chatkit.examples.config.ConfigurationActivity
import com.finclip.chatkit.examples.context.ContextProviderActivity
import com.finclip.chatkit.examples.conversation.ConversationManagementActivity
import com.finclip.chatkit.examples.full.FullFeatureActivity
import com.finclip.chatkit.examples.settings.AppSettings
import com.finclip.chatkit.examples.settings.ChatKitHelper
import com.finclip.chatkit.examples.simple.SimpleChatActivity
import com.google.android.material.switchmaterial.SwitchMaterial
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout

class MainActivity : AppCompatActivity() {

    private val examples = listOf(
        ExampleItem(
            "1. Simple Chat",
            "Basic chat functionality with minimal setup",
            SimpleChatActivity::class.java
        ),
        ExampleItem(
            "2. Configuration",
            "Customize welcome message, prompt starters, status banner",
            ConfigurationActivity::class.java
        ),
        ExampleItem(
            "3. Conversation Management",
            "Create, list, search, delete conversations",
            ConversationManagementActivity::class.java
        ),
        ExampleItem(
            "4. Context Providers",
            "Add device state, network status context",
            ContextProviderActivity::class.java
        ),
        ExampleItem(
            "5. Compose Example",
            "Jetpack Compose integration",
            ComposeExampleActivity::class.java
        ),
        ExampleItem(
            "6. Full Feature",
            "Complete example with all features",
            FullFeatureActivity::class.java
        ),
        ExampleItem(
            "7. Advanced APIs",
            "Low-level APIs, custom providers, configuration presets",
            AdvancedApiActivity::class.java
        ),
    )

    private var statusTextView: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        statusTextView = findViewById(R.id.statusText)
        updateStatusText()

        val recyclerView = findViewById<RecyclerView>(R.id.recyclerView)
        recyclerView.layoutManager = LinearLayoutManager(this)
        recyclerView.adapter = ExampleAdapter(examples) { example ->
            startActivity(Intent(this, example.activityClass))
        }
    }

    override fun onResume() {
        super.onResume()
        updateStatusText()
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_main, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_settings -> {
                showSettingsDialog()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun updateStatusText() {
        statusTextView?.text = ChatKitHelper.getStatusDescription()
    }

    private fun showSettingsDialog() {
        val dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_settings, null)

        val switchMock = dialogView.findViewById<SwitchMaterial>(R.id.switchMock)
        val serverUrlLayout = dialogView.findViewById<TextInputLayout>(R.id.serverUrlLayout)
        val editServerUrl = dialogView.findViewById<TextInputEditText>(R.id.editServerUrl)
        val btnResetDefault = dialogView.findViewById<android.widget.Button>(R.id.btnResetDefault)

        switchMock.isChecked = AppSettings.useMock
        editServerUrl.setText(AppSettings.serverUrl)

        fun updateServerUrlEnabled() {
            serverUrlLayout.isEnabled = !switchMock.isChecked
            editServerUrl.isEnabled = !switchMock.isChecked
        }
        updateServerUrlEnabled()

        switchMock.setOnCheckedChangeListener { _, _ ->
            updateServerUrlEnabled()
        }

        btnResetDefault.setOnClickListener {
            editServerUrl.setText(AppSettings.DEFAULT_SERVER_URL)
            switchMock.isChecked = false
        }

        AlertDialog.Builder(this)
            .setView(dialogView)
            .setPositiveButton("保存") { _, _ ->
                AppSettings.useMock = switchMock.isChecked
                val serverUrl = editServerUrl.text?.toString()?.trim()
                if (!serverUrl.isNullOrEmpty()) {
                    AppSettings.serverUrl = serverUrl
                }
                updateStatusText()
            }
            .setNegativeButton("取消", null)
            .show()
    }
}

data class ExampleItem(
    val title: String,
    val description: String,
    val activityClass: Class<*>
)

class ExampleAdapter(
    private val items: List<ExampleItem>,
    private val onClick: (ExampleItem) -> Unit
) : RecyclerView.Adapter<ExampleAdapter.ViewHolder>() {

    class ViewHolder(view: android.view.View) : RecyclerView.ViewHolder(view) {
        val title: android.widget.TextView = view.findViewById(R.id.title)
        val description: android.widget.TextView = view.findViewById(R.id.description)
    }

    override fun onCreateViewHolder(parent: android.view.ViewGroup, viewType: Int): ViewHolder {
        val view = android.view.LayoutInflater.from(parent.context)
            .inflate(R.layout.item_example, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.title.text = item.title
        holder.description.text = item.description
        holder.itemView.setOnClickListener { onClick(item) }
    }

    override fun getItemCount() = items.size
}
