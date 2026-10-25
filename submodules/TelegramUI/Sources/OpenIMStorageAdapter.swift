// OpenIMStorageAdapter.swift
// 将 OpenIM 消息集成到 TG 的本地存储层
// 让 TG 的数据库直接存储 OpenIM 的消息

import Foundation

// MARK: - OpenIM 存储适配器

class OpenIMStorageAdapter {
    static let shared = OpenIMStorageAdapter()
    
    private var tgDatabase: TGDatabaseManager?
    private var syncManager: SyncManager?
    
    init() {}
    
    // MARK: - 初始化
    
    func initialize(with databaseManager: TGDatabaseManager) {
        self.tgDatabase = databaseManager
        self.syncManager = SyncManager(database: databaseManager)
        
        print("✅ OpenIM 存储适配器已初始化")
    }
    
    // MARK: - 消息存储
    
    /// 保存 OpenIM 消息到 TG 数据库
    /// 直接继承 TG 的消息格式
    func storeMessage(_ message: OpenIMMessage, conversationID: String) {
        guard let db = tgDatabase else { return }
        
        // 转换为 TG 格式
        let tgMessage = convertToTGMessage(message, conversationID: conversationID)
        
        // 保存到 TG 数据库
        DispatchQueue.global(qos: .userInitiated).async {
            db.saveMessage(tgMessage)
        }
    }
    
    /// 批量保存消息
    func storeMessages(_ messages: [OpenIMMessage], conversationID: String) {
        guard let db = tgDatabase else { return }
        
        let tgMessages = messages.map { convertToTGMessage($0, conversationID: conversationID) }
        
        DispatchQueue.global(qos: .userInitiated).async {
            db.saveMessages(tgMessages)
        }
    }
    
    /// 查询消息
    func queryMessages(
        conversationID: String,
        limit: Int = 50,
        offset: Int = 0
    ) -> [TGMessage] {
        guard let db = tgDatabase else { return [] }
        
        return db.getMessages(
            conversationID: conversationID,
            limit: limit,
            offset: offset
        )
    }
    
    // MARK: - 会话存储
    
    /// 保存 OpenIM 会话到 TG 数据库
    func storeConversation(_ conversation: OpenIMConversation) {
        guard let db = tgDatabase else { return }
        
        let tgConversation = convertToTGConversation(conversation)
        
        DispatchQueue.global(qos: .userInitiated).async {
            db.saveConversation(tgConversation)
        }
    }
    
    /// 批量保存会话
    func storeConversations(_ conversations: [OpenIMConversation]) {
        guard let db = tgDatabase else { return }
        
        let tgConversations = conversations.map { convertToTGConversation($0) }
        
        DispatchQueue.global(qos: .userInitiated).async {
            db.saveConversations(tgConversations)
        }
    }
    
    /// 查询会话列表
    func queryConversations(limit: Int = 50) -> [TGConversation] {
        guard let db = tgDatabase else { return [] }
        
        return db.getConversations(limit: limit)
    }
    
    // MARK: - 用户信息存储
    
    /// 保存 OpenIM 用户信息
    func storeUserInfo(_ user: OpenIMUser) {
        guard let db = tgDatabase else { return }
        
        let tgUser = TGUserInfo(
            id: Int64(user.userID, radix: 10) ?? 0,
            name: user.nickname ?? user.userID,
            avatar: user.faceURL,
            status: .online,
            source: .openim
        )
        
        DispatchQueue.global(qos: .userInitiated).async {
            db.saveUserInfo(tgUser)
        }
    }
    
    // MARK: - 同步管理
    
    /// 启动 OpenIM 消息同步
    func startSynchronization(conversationID: String) {
        syncManager?.startSync(conversationID: conversationID)
    }
    
    /// 停止同步
    func stopSynchronization(conversationID: String) {
        syncManager?.stopSync(conversationID: conversationID)
    }
    
    // MARK: - 转换方法
    
    private func convertToTGMessage(_ message: OpenIMMessage, conversationID: String) -> TGMessage {
        return TGMessage(
            id: Int(message.id ?? "", radix: 10) ?? UUID().hashValue,
            peerId: Int64(conversationID, radix: 10) ?? 0,
            text: message.textContent ?? "",
            timestamp: Date(timeIntervalSince1970: TimeInterval(message.timestamp)),
            source: .openim
        )
    }
    
    private func convertToTGConversation(_ conversation: OpenIMConversation) -> TGConversation {
        return TGConversation(
            id: Int64(conversation.conversationID ?? "0", radix: 10) ?? 0,
            title: conversation.conversationName ?? "",
            lastMessage: conversation.latestMessageContent ?? "",
            lastMessageDate: Date(timeIntervalSince1970: TimeInterval(conversation.latestMessageTimestamp)),
            unreadCount: conversation.unreadCount,
            source: .openim
        )
    }
}

// MARK: - TG 数据库管理器（接口）

protocol TGDatabaseManager {
    func saveMessage(_ message: TGMessage)
    func saveMessages(_ messages: [TGMessage])
    func getMessages(conversationID: String, limit: Int, offset: Int) -> [TGMessage]
    
    func saveConversation(_ conversation: TGConversation)
    func saveConversations(_ conversations: [TGConversation])
    func getConversations(limit: Int) -> [TGConversation]
    
    func saveUserInfo(_ user: TGUserInfo)
}

// MARK: - TG 用户信息模型

struct TGUserInfo: Codable {
    let id: Int64
    let name: String
    let avatar: String?
    let status: UserStatus
    let source: UserSource
    
    enum UserStatus: String, Codable {
        case online
        case offline
        case away
    }
    
    enum UserSource: String, Codable {
        case telegram
        case openim
    }
}

// MARK: - 同步管理器

class SyncManager {
    private let database: TGDatabaseManager
    private var activeSyncs: [String: Timer] = [:]
    private var imClient: OpenIMClient?
    
    init(database: TGDatabaseManager) {
        self.database = database
    }
    
    /// 启动定期同步
    func startSync(conversationID: String) {
        // 避免重复同步
        if activeSyncs[conversationID] != nil {
            return
        }
        
        // 立即同步一次
        performSync(conversationID: conversationID)
        
        // 每 5 秒同步一次
        let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.performSync(conversationID: conversationID)
        }
        
        activeSyncs[conversationID] = timer
        
        print("✅ 已启动会话 \(conversationID) 的同步")
    }
    
    /// 停止同步
    func stopSync(conversationID: String) {
        activeSyncs[conversationID]?.invalidate()
        activeSyncs.removeValue(forKey: conversationID)
        
        print("🛑 已停止会话 \(conversationID) 的同步")
    }
    
    /// 执行一次同步
    private func performSync(conversationID: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 从 OpenIM 获取新消息
            self?.imClient?.getMessages(conversationID: conversationID, limit: 50) { messages, error in
                if let messages = messages {
                    // 保存到 TG 数据库
                    self?.database.saveMessages(
                        messages.map { TGMessage(
                            id: Int($0.id ?? "", radix: 10) ?? 0,
                            peerId: Int64(conversationID, radix: 10) ?? 0,
                            text: $0.textContent ?? "",
                            timestamp: Date(timeIntervalSince1970: TimeInterval($0.timestamp)),
                            source: .openim
                        )}
                    )
                    
                    // 通知 UI 更新
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("OpenIMMessagesUpdated"),
                            object: ["conversationID": conversationID, "count": messages.count]
                        )
                    }
                }
            }
        }
    }
}

// MARK: - 实际的 TG 数据库实现示例

class TGDatabaseImpl: TGDatabaseManager {
    private let valueBox: ValueBox  // TG 自己的数据库
    
    init(valueBox: ValueBox) {
        self.valueBox = valueBox
    }
    
    // MARK: - 消息操作
    
    func saveMessage(_ message: TGMessage) {
        // 保存单条消息到 ValueBox
        // 键: "message_<peerId>_<id>"
        // 值: message 的 JSON 序列化
        
        let key = "message_\(message.peerId)_\(message.id)"
        let data = try? JSONEncoder().encode(message)
        
        DispatchQueue.main.async { [weak self] in
            if let data = data {
                self?.valueBox.set(key: key, value: data)
            }
        }
    }
    
    func saveMessages(_ messages: [TGMessage]) {
        for message in messages {
            saveMessage(message)
        }
    }
    
    func getMessages(conversationID: String, limit: Int, offset: Int) -> [TGMessage] {
        // 从 ValueBox 读取消息
        let prefix = "message_\(conversationID)_"
        let results = fetchMessages(prefix: prefix)
        
        guard offset < results.count else { return [] }
        let start = offset
        let end = min(start + limit, results.count)
        return Array(results[start..<end])
    }
    
    // MARK: - 会话操作
    
    func saveConversation(_ conversation: TGConversation) {
        let key = "conversation_\(conversation.id)"
        let data = try? JSONEncoder().encode(conversation)
        
        DispatchQueue.main.async { [weak self] in
            if let data = data {
                self?.valueBox.set(key: key, value: data)
            }
        }
    }
    
    func saveConversations(_ conversations: [TGConversation]) {
        for conversation in conversations {
            saveConversation(conversation)
        }
    }
    
    func getConversations(limit: Int) -> [TGConversation] {
        let prefix = "conversation_"
        let results = fetchConversations(prefix: prefix)
        
        guard limit < results.count else { return results }
        return Array(results[0..<limit])
    }
    
    // MARK: - 私有读取辅助
    
    /// 读取所有以 prefix 开头的消息，按时间升序排序
    private func fetchMessages(prefix: String) -> [TGMessage] {
        var results: [TGMessage] = []
        for key in valueBox.keys(withPrefix: prefix) {
            guard let data = valueBox.get(key: key),
                  let message = try? JSONDecoder().decode(TGMessage.self, from: data) else {
                continue
            }
            results.append(message)
        }
        return results.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// 读取所有以 prefix 开头的会话，按最后消息时间降序排序
    private func fetchConversations(prefix: String) -> [TGConversation] {
        var results: [TGConversation] = []
        for key in valueBox.keys(withPrefix: prefix) {
            guard let data = valueBox.get(key: key),
                  let conversation = try? JSONDecoder().decode(TGConversation.self, from: data) else {
                continue
            }
            results.append(conversation)
        }
        return results.sorted { $0.lastMessageDate > $1.lastMessageDate }
    }
    
    // MARK: - 用户信息
    
    func saveUserInfo(_ user: TGUserInfo) {
        let key = "user_\(user.id)"
        let data = try? JSONEncoder().encode(user)
        
        DispatchQueue.main.async { [weak self] in
            if let data = data {
                self?.valueBox.set(key: key, value: data)
            }
        }
    }
}

// MARK: - ValueBox 存根（TG 的实际数据库）

protocol ValueBox {
    func set(key: String, value: Data)
    func get(key: String) -> Data?
    func removeValue(key: String)
    /// 返回所有以指定前缀开头的键
    func keys(withPrefix prefix: String) -> [String]
}
