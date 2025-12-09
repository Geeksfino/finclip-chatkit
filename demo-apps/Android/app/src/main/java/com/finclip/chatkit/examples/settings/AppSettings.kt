package com.finclip.chatkit.examples.settings

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

object AppSettings {
    private const val PREF_NAME = "chatkit_examples_settings"
    private const val KEY_SERVER_URL = "server_url"
    private const val KEY_USE_MOCK = "use_mock"
    private const val KEY_USER_ID = "user_id"

    const val DEFAULT_SERVER_URL = "http://localhost:3000/agent"

    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }

    var serverUrl: String
        get() = prefs.getString(KEY_SERVER_URL, DEFAULT_SERVER_URL) ?: DEFAULT_SERVER_URL
        set(value) = prefs.edit { putString(KEY_SERVER_URL, value) }

    var useMock: Boolean
        get() = prefs.getBoolean(KEY_USE_MOCK, false)
        set(value) = prefs.edit { putBoolean(KEY_USE_MOCK, value) }

    var userId: String
        get() = prefs.getString(KEY_USER_ID, null) ?: generateUserId()
        set(value) = prefs.edit { putString(KEY_USER_ID, value) }

    private fun generateUserId(): String {
        val newId = "user-${System.currentTimeMillis()}"
        userId = newId
        return newId
    }

    fun reset() {
        prefs.edit {
            remove(KEY_SERVER_URL)
            remove(KEY_USE_MOCK)
        }
    }
}
