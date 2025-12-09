package com.finclip.chatkit.examples.settings

import android.content.Context
import com.finclip.chatkit.ChatKit
import com.finclip.chatkit.ChatKitConfiguration
import com.finclip.chatkit.ChatKitCoordinator
import com.finclip.chatkit.ConversationTitleProvider
import com.finclip.chatkit.examples.mock.MockRuntime

object ChatKitHelper {

    private var mockRuntime: MockRuntime? = null

    fun createCoordinator(
        context: Context,
        chatKitConfiguration: ChatKitConfiguration? = null,
        titleProvider: ConversationTitleProvider? = null
    ): ChatKitCoordinator {
        return if (AppSettings.useMock) {
            createMockCoordinator(chatKitConfiguration, titleProvider)
        } else {
            createRealCoordinator(context, chatKitConfiguration, titleProvider)
        }
    }

    private fun createRealCoordinator(
        context: Context,
        chatKitConfiguration: ChatKitConfiguration?,
        titleProvider: ConversationTitleProvider?
    ): ChatKitCoordinator {
        val serverUrl = AppSettings.serverUrl
        val userId = AppSettings.userId

        return ChatKit.createCoordinator(
            context = context,
            serverURL = serverUrl,
            userId = userId,
            titleProvider = titleProvider,
            chatKitConfiguration = chatKitConfiguration
        )
    }

    private fun createMockCoordinator(
        chatKitConfiguration: ChatKitConfiguration?,
        titleProvider: ConversationTitleProvider?
    ): ChatKitCoordinator {
        // Reuse or create MockRuntime
        val runtime = mockRuntime ?: MockRuntime().also { mockRuntime = it }

        return ChatKit.createCoordinatorWithRuntime(
            customRuntime = runtime,
            titleProvider = titleProvider,
            chatKitConfiguration = chatKitConfiguration
        )
    }

    fun isMockMode(): Boolean = AppSettings.useMock

    fun getServerUrl(): String = AppSettings.serverUrl

    fun getMockRuntime(): MockRuntime {
        return mockRuntime ?: MockRuntime().also { mockRuntime = it }
    }

    fun getStatusDescription(): String {
        return if (AppSettings.useMock) {
            "Mock 模式 (离线)"
        } else {
            "服务器: ${AppSettings.serverUrl}"
        }
    }

    /**
     * Reset mock runtime (useful when switching modes)
     */
    fun resetMockRuntime() {
        mockRuntime = null
    }
}
