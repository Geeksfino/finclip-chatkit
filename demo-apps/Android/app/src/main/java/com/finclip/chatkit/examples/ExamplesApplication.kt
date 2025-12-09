package com.finclip.chatkit.examples

import android.app.Application
import com.finclip.chatkit.examples.settings.AppSettings
import com.finclip.chatkit.logging.ChatKitLogger
import com.finclip.chatkit.logging.LogLevel

class ExamplesApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        AppSettings.init(this)
        ChatKitLogger.setMinLogLevel(LogLevel.DEBUG)
    }
}
