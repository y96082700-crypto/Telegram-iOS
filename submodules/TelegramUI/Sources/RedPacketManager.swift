// RedPacketManager.swift
// 红包业务逻辑层 - 基于悟空的数据格式，为 TG 重新设计
//
// 职责：
// 1. 红包消息识别和解析
// 2. 红包业务操作（查询、领取等）
// 3. 红包缓存管理
// 4. 与 OpenIM 集成

import Foundation
import SwiftSignalKit

/// 红包数据模型
public struct RedPacket: Codable {
    public let id: Int64
    public let blessing: String        // 祝福语
    public let money: String           // 金额
    public let groupId: String         // 群组 ID
    public let toUserId: String?       // 接收者（专属红包）
    public let activityType: Int       // 2=群红包, 3=专属红包
    public let activityScope: Int      // 1=P2P, 2=群
    
    public init(from dict: [String: Any]) {
        self.id = dict["id"] as? Int64 ?? 0
        self.blessing = dict["message"] as? String ?? "恭喜发财"
        self.money = dict["money"] as? String ?? "0.00"
        self.groupId = dict["group_id"] as? String ?? ""
        self.toUserId = dict["to_user_id"] as? String
        self.activityType = dict["activity_type"] as? Int ?? 2
        self.activityScope = dict["activity_scope"] as? Int ?? 2
    }
}

/// 红包管理器
public class RedPacketManager {
    public static let shared = RedPacketManager()
    
    private let redPacketCustomType = 305
    private let notificationName = NSNotification.Name("RedPacketReceived")
    
    // MARK: - 消息识别和解析
    
    /// 检查消息是否是红包
    public func isRedPacketMessage(_ content: String?) -> Bool {
        guard let content = content,
              let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        
        let customType = json["customType"] ?? json["custom_type"]
        if let type = customType as? Int {
            return type == redPacketCustomType
        }
        if let type = customType as? NSNumber {
            return type.intValue == redPacketCustomType
        }
        return false
    }
    
    /// 解析红包消息
    public func parseRedPacketMessage(_ content: String?) -> RedPacket? {
        guard isRedPacketMessage(content) else { return nil }
        guard let content = content,
              let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return RedPacket(from: json)
    }
    
    // MARK: - 业务操作
    
    /// 领取红包
    public func claimRedPacket(id: Int64) -> Signal<RedPacketInfo, BizError> {
        return BizClient.shared.post(
            path: "/api/red-packet/claim",
            body: ["id": NSNumber(value: id)]
        )
    }
    
    /// 查询红包详情
    public func queryRedPacket(id: Int64) -> Signal<RedPacketInfo, BizError> {
        return BizClient.shared.get(path: "/api/red-packet/info/\(id)")
    }
    
    /// 查询红包列表
    public func listRedPackets() -> Signal<[RedPacketInfo], BizError> {
        return BizClient.shared.get(path: "/api/red-packet/list")
    }
    
    // MARK: - 消息事件
    
    /// 处理接收到的红包消息
    public func handleRedPacketMessage(_ messageContent: String) {
        guard let redPacket = parseRedPacketMessage(messageContent) else {
            return
        }
        
        // 发送事件通知
        NotificationCenter.default.post(
            name: notificationName,
            object: redPacket
        )
    }
    
    /// 获取红包事件通知名
    public var redPacketNotification: NSNotification.Name {
        return notificationName
    }
}
