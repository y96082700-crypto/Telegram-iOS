// OpenIMModels.swift
// OpenIM 侧的轻量数据模型。
//
// 背景：原实现直接引用 OpenIM SDK 的 `Message` / `Conversation` / `User` 类型，
// 但 TG-iOS 并没有集成 OpenIM SDK（没有该依赖），直接引用会编译失败。
// 这里定义一套自包含的等价模型，字段对齐悟空安卓端 / OpenIM SDK 的 JSON 结构，
// 后续真正接入 OpenIM SDK 时，只需把这些模型换成 SDK 类型即可。
//
// 注意：这些类型刻意加了 `OpenIM` 前缀，避免与 TelegramUI 模块内已有的
// `Message`（Postbox）、`User` 等类型重名导致遮蔽。

import Foundation

// MARK: - OpenIM 消息

struct OpenIMMessage {
    /// 消息 ID（服务端下发）
    let id: String?
    /// 会话 ID
    let conversationID: String?
    /// 消息发送者 ID
    let senderID: String?
    /// 消息正文
    let textContent: String?
    /// 服务端时间戳（秒）
    let timestamp: Int64
    /// 消息类型：1=文本，101=自定义（红包等）
    let contentType: Int
    /// 自定义消息的 payload（红包 JSON 等）
    let customData: [String: Any]?
    /// 会话类型：1=单聊，2=群聊
    let conversationType: Int

    init(
        id: String?,
        conversationID: String?,
        senderID: String?,
        textContent: String?,
        timestamp: Int64,
        contentType: Int = 1,
        customData: [String: Any]? = nil,
        conversationType: Int = 1
    ) {
        self.id = id
        self.conversationID = conversationID
        self.senderID = senderID
        self.textContent = textContent
        self.timestamp = timestamp
        self.contentType = contentType
        self.customData = customData
        self.conversationType = conversationType
    }

    /// 从服务端 JSON 字典构造
    init?(json: [String: Any]) {
        guard let id = json["msgID"] as? String ?? json["msgId"] as? String else { return nil }
        self.id = id
        self.conversationID = json["conversationID"] as? String ?? json["conversationId"] as? String
        self.senderID = json["sendID"] as? String ?? json["senderID"] as? String ?? json["sendId"] as? String
        self.textContent = json["content"] as? String
        self.timestamp = (json["createTime"] as? Int64) ?? (json["createTime"] as? Int).map(Int64.init) ?? 0
        self.contentType = (json["contentType"] as? Int) ?? 1
        self.customData = json["customData"] as? [String: Any] ?? json["ex"] as? [String: Any]
        self.conversationType = (json["conversationType"] as? Int) ?? 1
    }

    /// 红包等自定义消息的 customType（用于消息识别）
    var customType: Int? {
        guard let customData = customData else { return nil }
        return (customData["customType"] as? Int) ?? (customData["custom_type"] as? Int)
    }
}

// MARK: - OpenIM 会话

struct OpenIMConversation {
    let conversationID: String?
    let conversationName: String?
    let latestMessageContent: String?
    let latestMessageTimestamp: Int64
    let unreadCount: Int

    init(
        conversationID: String?,
        conversationName: String?,
        latestMessageContent: String?,
        latestMessageTimestamp: Int64,
        unreadCount: Int
    ) {
        self.conversationID = conversationID
        self.conversationName = conversationName
        self.latestMessageContent = latestMessageContent
        self.latestMessageTimestamp = latestMessageTimestamp
        self.unreadCount = unreadCount
    }

    init?(json: [String: Any]) {
        self.conversationID = json["conversationID"] as? String ?? json["conversationId"] as? String
        self.conversationName = json["conversationName"] as? String
        self.latestMessageContent = json["latestMsgContent"] as? String ?? json["latestMessageContent"] as? String
        self.latestMessageTimestamp = (json["latestMsgTime"] as? Int64) ?? (json["latestMsgTime"] as? Int).map(Int64.init) ?? 0
        self.unreadCount = (json["unreadCount"] as? Int) ?? 0
    }
}

// MARK: - OpenIM 用户

struct OpenIMUser {
    let userID: String
    let nickname: String?
    let faceURL: String?

    init(userID: String, nickname: String? = nil, faceURL: String? = nil) {
        self.userID = userID
        self.nickname = nickname
        self.faceURL = faceURL
    }

    init?(json: [String: Any]) {
        guard let userID = json["userID"] as? String ?? json["userId"] as? String else { return nil }
        self.userID = userID
        self.nickname = json["nickname"] as? String ?? json["name"] as? String
        self.faceURL = json["faceURL"] as? String ?? json["faceUrl"] as? String
    }
}
