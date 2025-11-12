//
//  LocalizationHelper.swift
//  Simple
//
//  Helper for managing localization in the demo app
//

import Foundation

/// Helper class for managing localization
class LocalizationHelper {
    
    // Embedded localization strings as fallback
    private static let localizedStrings: [String: [String: String]] = [
        "en": [
            "app.title": "Simple",
            "app.welcome": "Connected! Send a message to start chatting.",
            "app.error": "Error",
            "app.ok": "OK",
            "app.cancel": "Cancel",
            "status.connecting": "Connecting...",
            "status.reconnecting": "Reconnecting...",
            "status.connected": "Connected",
            "status.disconnected": "Disconnected",
            "composer.tools": "Tools",
            "tool.expedia": "Expedia",
            "tool.booking": "Booking.com",
            "tool.coursera": "Coursera",
            "settings.language": "Language",
            "settings.language.en": "English",
            "settings.language.zhHans": "简体中文",
            "settings.language.zhHant": "繁體中文",
            "settings.language.change": "Change Language",
            "settings.language.restart": "Language Changed",
            "settings.language.restartMessage": "Please restart the app to apply the new language setting.",
            "settings.language.restartButton": "OK",
        ],
        "zh-Hans": [
            "app.title": "Simple",
            "app.welcome": "已连接！发送消息开始聊天。",
            "app.error": "错误",
            "app.ok": "确定",
            "app.cancel": "取消",
            "status.connecting": "连接中...",
            "status.reconnecting": "重新连接中...",
            "status.connected": "已连接",
            "status.disconnected": "已断开连接",
            "composer.tools": "工具",
            "tool.expedia": "Expedia",
            "tool.booking": "Booking.com",
            "tool.coursera": "Coursera",
            "settings.language": "语言",
            "settings.language.en": "English",
            "settings.language.zhHans": "简体中文",
            "settings.language.zhHant": "繁體中文",
            "settings.language.change": "更改语言",
            "settings.language.restart": "语言已更改",
            "settings.language.restartMessage": "请重启应用以应用新的语言设置。",
            "settings.language.restartButton": "确定",
        ],
        "zh-Hant": [
            "app.title": "Simple",
            "app.welcome": "已連接！發送訊息開始聊天。",
            "app.error": "錯誤",
            "app.ok": "確定",
            "app.cancel": "取消",
            "status.connecting": "連接中...",
            "status.reconnecting": "重新連接中...",
            "status.connected": "已連接",
            "status.disconnected": "已斷開連接",
            "composer.tools": "工具",
            "tool.expedia": "Expedia",
            "tool.booking": "Booking.com",
            "tool.coursera": "Coursera",
            "settings.language": "語言",
            "settings.language.en": "English",
            "settings.language.zhHans": "简体中文",
            "settings.language.zhHant": "繁體中文",
            "settings.language.change": "更改語言",
            "settings.language.restart": "語言已更改",
            "settings.language.restartMessage": "請重啟應用以應用新的語言設置。",
            "settings.language.restartButton": "確定",
        ]
    ]
    
    /// Get localized string for key
    static func localized(_ key: String) -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        
        // Map language codes to our supported languages
        let mappedCode: String
        if languageCode.hasPrefix("zh") {
            if Locale.current.language.region?.identifier == "HK" || 
               Locale.current.language.region?.identifier == "TW" ||
               Locale.current.language.region?.identifier == "MO" {
                mappedCode = "zh-Hant"
            } else {
                mappedCode = "zh-Hans"
            }
        } else {
            mappedCode = "en"
        }
        
        if let strings = localizedStrings[mappedCode],
           let value = strings[key] {
            return value
        }
        
        // Fallback to English
        if let strings = localizedStrings["en"],
           let value = strings[key] {
            return value
        }
        
        return key
    }
}
