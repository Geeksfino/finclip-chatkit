package com.finclip.chatkit.examples.compose

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.finclip.chatkit.ChatKit
import com.finclip.chatkit.ChatKitCoordinator
import com.finclip.chatkit.compose.ChatKitChatView
import com.finclip.chatkit.compose.ConnectionStatusBanner
import com.finclip.chatkit.error.ChatKitError
import com.finclip.chatkit.examples.settings.ChatKitHelper
import com.finclip.chatkit.examples.ui.theme.ChatKitExamplesTheme
import com.finclip.chatkit.model.ConversationRecord
import java.util.UUID

class ComposeExampleActivity : ComponentActivity() {

    private val agentId = UUID.fromString("00000000-0000-0000-0000-000000000001")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            ChatKitExamplesTheme {
                ComposeExampleScreen(
                    agentId = agentId,
                    onBack = { finish() }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ComposeExampleScreen(
    agentId: UUID,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    var coordinator by remember { mutableStateOf<ChatKitCoordinator?>(null) }
    var conversationRecord by remember { mutableStateOf<ConversationRecord?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        try {
            // 添加延迟以演示加载动画 (1秒)
            kotlinx.coroutines.delay(1000)
            
            // 使用 ChatKitHelper 创建 coordinator，确保使用正确的服务器配置
            val newCoordinator = ChatKitHelper.createCoordinator(context)
            coordinator = newCoordinator

            val (record, _) = newCoordinator.startConversation(
                agentId = agentId,
                title = "Compose Chat"
            )
            conversationRecord = record
            isLoading = false

        } catch (e: Exception) {
            val error = ChatKitError.from(e)
            errorMessage = error.userMessage
            isLoading = false
        }
    }

    val connectionStatus by remember(coordinator) {
        coordinator?.connectionStatus ?: kotlinx.coroutines.flow.MutableStateFlow("Disconnected")
    }.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Compose Example") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (!connectionStatus.contains("Connected", ignoreCase = true)) {
                ConnectionStatusBanner(
                    status = connectionStatus,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f),
                contentAlignment = Alignment.Center
            ) {
                when {
                    isLoading -> {
                        CircularProgressIndicator()
                    }
                    errorMessage != null -> {
                        ErrorContent(
                            message = errorMessage!!,
                            onRetry = {
                                errorMessage = null
                                isLoading = true
                            }
                        )
                    }
                    conversationRecord != null -> {
                        ChatKitChatView(
                            sessionId = conversationRecord!!.id,
                            modifier = Modifier.fillMaxSize(),
                            onMessageSent = { },
                            onError = { error ->
                                errorMessage = error.userMessage
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ErrorContent(
    message: String,
    onRetry: () -> Unit
) {
    Column(
        modifier = Modifier.padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.error
        )
        Button(onClick = onRetry) {
            Text("Retry")
        }
    }
}
