// BizIntegrationAdapter.swift
// 业务模块适配层 - 处理 OpenIM SDK 缺失的情况

import Foundation

/// IMController 的本地适配 (原 OUICore 依赖)
class IMController {
    static let shared = IMController()
    
    var businessToken: String? {
        UserDefaults.standard.string(forKey: "businessTokenKey")
    }
    
    var businessServer: String {
        get {
            UserDefaults.standard.string(forKey: "io.openim.business.server")
                ?? "https://api.eaqenw.cn"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "io.openim.business.server")
        }
    }
    
    var sdkAPIAdrr: String {
        UserDefaults.standard.string(forKey: "io.openim.sdk.api") ?? ""
    }
}

// 注：原文件在这里给 BizHelper 扩展了一个 `num(_:) -> NSNumber?`，
// 与 BizHelper.swift 中的 `num(_:) -> Double` 重复且会引发重载歧义，
// 因此移除该扩展，由 BizHelper.swift 统一提供数值转换。

/// 消息模型适配
/// 注意：不可命名为 `Message` —— TelegramUI 模块内 Postbox 的 `Message` 类型被大量引用，
/// 同模块内重名会导致类型遮蔽、整个模块编译失败。
struct BizMessage {
    let id: String
    let content: String
    let senderId: String
    let groupId: String?
    let timestamp: Int64
}
