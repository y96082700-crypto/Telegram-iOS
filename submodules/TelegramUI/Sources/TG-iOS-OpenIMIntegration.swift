// File: TG-iOS/submodules/TelegramUI/Sources/OpenIMIntegration.swift
// Purpose: OpenIM 集成初始化和管理

import Foundation
import UIKit
import SwiftSignalKit
import TelegramCore

// MARK: - OpenIM 集成管理器

class OpenIMIntegration {
    static let shared = OpenIMIntegration()
    
    private var networkAdapter: OpenIMNetworkAdapter?
    private var storageAdapter: OpenIMStorageAdapter?
    private var isInitialized = false
    
    private init() {}
    
    // MARK: - 初始化（在 AppDelegate 中调用）
    
    func initialize(
        serverURL: String,
        wsURL: String,
        userId: String,
        token: String,
        databaseManager: TGDatabaseManager
    ) {
        guard !isInitialized else { return }
        
        // 初始化网络适配器
        let imConfig = OpenIMConfig(
            serverURL: serverURL,
            wsURL: wsURL,
            userId: userId,
            token: token
        )
        
        networkAdapter = OpenIMNetworkAdapter()
        networkAdapter?.initialize(with: imConfig)
        
        // 初始化存储适配器
        storageAdapter = OpenIMStorageAdapter()
        storageAdapter?.initialize(with: databaseManager)
        
        isInitialized = true
        
        print("✅ OpenIM 集成已初始化")
        print("   服务器: \(serverURL)")
        print("   用户 ID: \(userId)")
    }
    
    // MARK: - 获取消息（双源合并）
    
    func getMessages(
        peerId: Int64,
        limit: Int = 50,
        completion: @escaping (Result<[TGMessage], Error>) -> Void
    ) {
        guard let adapter = networkAdapter else {
            completion(.failure(OpenIMError.notInitialized))
            return
        }
        
        adapter.getMessages(for: peerId, limit: limit, completion: completion)
    }
    
    // MARK: - 获取会话列表（双源合并）
    
    func getConversations(completion: @escaping (Result<[TGConversation], Error>) -> Void) {
        guard let adapter = networkAdapter else {
            completion(.failure(OpenIMError.notInitialized))
            return
        }
        
        adapter.getConversations(completion: completion)
    }
    
    // MARK: - 发送消息（双通道）
    
    func sendMessage(
        to peerId: Int64,
        text: String,
        completion: @escaping (Result<TGMessage, Error>) -> Void
    ) {
        guard let adapter = networkAdapter else {
            completion(.failure(OpenIMError.notInitialized))
            return
        }
        
        adapter.sendMessage(to: peerId, text: text, completion: completion)
    }
}

// MARK: - 错误定义

enum OpenIMError: LocalizedError {
    case notInitialized
    case networkError(String)
    case syncError(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "OpenIM 未初始化"
        case .networkError(let msg):
            return "网络错误: \(msg)"
        case .syncError(let msg):
            return "同步错误: \(msg)"
        }
    }
}

// MARK: - 通知事件

extension Notification.Name {
    static let openIMMessageReceived = Notification.Name("OpenIMMessageReceived")
    static let openIMConversationUpdated = Notification.Name("OpenIMConversationUpdated")
    static let openIMConnectionStateChanged = Notification.Name("OpenIMConnectionStateChanged")
}
