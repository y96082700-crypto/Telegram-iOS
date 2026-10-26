// BizModels.swift
// 业务系统的数据模型 - 基础定义

import Foundation

// MARK: - API 响应格式

public struct BizResp<T: Decodable>: Decodable {
    public let code: Int
    public let msg: String?
    public let data: T?
    
    enum CodingKeys: String, CodingKey {
        case code, msg, data
    }
}

// MARK: - 红包相关

/// 红包详情（对应服务端 `POST /biz/redpacket/detail` 的 data）。
///
/// 字段名取自安卓端真实用法（反编译 `sHEeHguHZhxD8ndpov` /
/// `thrdzehVsbGC8ndpou` / `fJVFKrEKkfWK8ndpof`），服务端同时存在
/// 驼峰与蛇形两种写法，因此每个字段都做了双写兼容：
///
/// | 字段             | 服务端键名（两种都兼容）        |
/// |----------------|------------------------------|
/// | id             | `redPacketId` / `red_packet_id` |
/// | message        | `blessing` / `message`        |
/// | money          | `money`                      |
/// | groupId        | `groupId` / `group_id`        |
/// | toUserId       | `toUserId` / `to_user_id`     |
/// | activityType   | `activity_type`               |
/// | activityScope  | `activity_scope`              |
public struct RedPacketInfo: Codable {
    public let id: Int64
    public let message: String           // 祝福语
    public let money: String             // 金额
    public let groupId: String           // 群组ID
    public let toUserId: String?         // 接收者（专属红包）
    public let activityType: Int         // 2=群红包, 3=专属红包
    public let activityScope: Int        // 1=P2P, 2=群

    /// 发起人 id
    public let sendId: String?
    /// 发起人昵称
    public let sendName: String?
    /// 红包皮肤 id
    public let skinId: Int?
    /// 红包皮肤名
    public let skinName: String?
    /// 已抢个数
    public let claimedCount: Int?
    /// 是否已抢完
    public let allClaimed: Bool?
    /// 是否已过期
    public let expired: Bool?
    /// 红包状态
    public let status: Int?

    /// 编码用的键：与属性名一一对应，输出驼峰风格。
    enum CodingKeys: String, CodingKey {
        case id
        case message
        case money
        case groupId
        case toUserId
        case activityType
        case activityScope
        case sendId
        case sendName
        case skinId
        case skinName
        case claimedCount
        case allClaimed
        case expired
        case status
    }

    /// 解码用的键：服务端真实键名（驼峰 + 蛇形双写兼容）。
    enum DecodingKeys: String, CodingKey {
        case id
        case message
        case money
        case groupId
        case toUserId
        case activityType
        case activityScope
        case sendId
        case sendName
        case skinId
        case skinName
        case claimedCount
        case allClaimed
        case expired
        case status

        // 服务端真实键名
        case redPacketId = "redPacketId"
        case redPacketIdSnake = "red_packet_id"
        case blessing = "blessing"
        case groupIdSnake = "group_id"
        case toUserIdSnake = "to_user_id"
        case activityTypeSnake = "activity_type"
        case activityScopeSnake = "activity_scope"
        case sendIdSnake = "send_id"
        case sendNameSnake = "send_name"
        case skinIdSnake = "skin_id"
        case skinNameSnake = "skin_name"
        case claimedCountSnake = "claimed_count"
        case allClaimedSnake = "all_claimed"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DecodingKeys.self)
        let any = c

        // id: redPacketId / red_packet_id / id
        if let v = try? any.decode(Int64.self, forKey: .redPacketId) {
            id = v
        } else if let v = try? any.decode(Int64.self, forKey: .redPacketIdSnake) {
            id = v
        } else {
            id = (try? any.decode(Int64.self, forKey: .id)) ?? 0
        }

        // message: blessing / message
        if let v = try? any.decode(String.self, forKey: .blessing) {
            message = v
        } else {
            message = (try? any.decode(String.self, forKey: .message)) ?? "恭喜发财"
        }

        money = (try? any.decode(String.self, forKey: .money)) ?? "0.00"

        if let v = try? any.decode(String.self, forKey: .groupId) {
            groupId = v
        } else {
            groupId = (try? any.decode(String.self, forKey: .groupIdSnake)) ?? ""
        }

        if let v = try? any.decode(String.self, forKey: .toUserId) {
            toUserId = v
        } else {
            toUserId = try? any.decode(String.self, forKey: .toUserIdSnake)
        }

        if let v = try? any.decode(Int.self, forKey: .activityType) {
            activityType = v
        } else {
            activityType = (try? any.decode(Int.self, forKey: .activityTypeSnake)) ?? 2
        }

        if let v = try? any.decode(Int.self, forKey: .activityScope) {
            activityScope = v
        } else {
            activityScope = (try? any.decode(Int.self, forKey: .activityScopeSnake)) ?? 2
        }

        if let v = try? any.decode(String.self, forKey: .sendId) {
            sendId = v
        } else {
            sendId = try? any.decode(String.self, forKey: .sendIdSnake)
        }
        if let v = try? any.decode(String.self, forKey: .sendName) {
            sendName = v
        } else {
            sendName = try? any.decode(String.self, forKey: .sendNameSnake)
        }
        skinId = (try? any.decode(Int.self, forKey: .skinId))
            ?? (try? any.decode(Int.self, forKey: .skinIdSnake))
        skinName = (try? any.decode(String.self, forKey: .skinName))
            ?? (try? any.decode(String.self, forKey: .skinNameSnake))
        claimedCount = (try? any.decode(Int.self, forKey: .claimedCount))
            ?? (try? any.decode(Int.self, forKey: .claimedCountSnake))
        allClaimed = (try? any.decode(Bool.self, forKey: .allClaimed))
            ?? (try? any.decode(Bool.self, forKey: .allClaimedSnake))
        expired = try? any.decode(Bool.self, forKey: .expired)
        status = try? any.decode(Int.self, forKey: .status)
    }

    /// 编码：输出驼峰键，与服务端实际返回的结构保持一致。
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(message, forKey: .message)
        try c.encode(money, forKey: .money)
        try c.encode(groupId, forKey: .groupId)
        try c.encodeIfPresent(toUserId, forKey: .toUserId)
        try c.encode(activityType, forKey: .activityType)
        try c.encode(activityScope, forKey: .activityScope)
        try c.encodeIfPresent(sendId, forKey: .sendId)
        try c.encodeIfPresent(sendName, forKey: .sendName)
        try c.encodeIfPresent(skinId, forKey: .skinId)
        try c.encodeIfPresent(skinName, forKey: .skinName)
        try c.encodeIfPresent(claimedCount, forKey: .claimedCount)
        try c.encodeIfPresent(allClaimed, forKey: .allClaimed)
        try c.encodeIfPresent(expired, forKey: .expired)
        try c.encodeIfPresent(status, forKey: .status)
    }
}

// MARK: - 用户扩展

public struct UserExtensionInfo: Codable {
    public let numberLevel: String?       // 号码等级
    public let showNumber: String?        // 展示号码
    public let vipLevel: Int?            // VIP等级
    public let vipExpire: String?        // VIP过期时间
    
    enum CodingKeys: String, CodingKey {
        case numberLevel = "number_level"
        case showNumber = "show_number"
        case vipLevel = "vip_level"
        case vipExpire = "vip_expire"
    }
}

// MARK: - 应用配置

/// 业务后端 `GET /biz/app/config` 的响应体。
///
/// 实测（2026-10-26，`https://api.eaqenw.cn/biz/app/config`）返回的**驼峰**键：
///
/// ```json
/// {"code":0,"msg":"ok","data":{
///   "mulUserId":"",
///   "rechargeAmounts":[50,100,200,500,1000],
///   "rechargeUrl":"http://47.110.147.231/hb-trade/",
///   "redPacketExpireHours":0,
///   "redPacketFeeEnabled":false,
///   "svipMonthly":120,
///   "tradeHallUrl":"http://47.110.147.231/hb-trade/#/pages/tradeHall/tradeHall",
///   "vipMonthly":1,
///   "withdrawAmounts":[50,100,200,500,1000],
///   "withdrawUrl":"http://47.110.147.231/hb-trade/#/pages/my/my",
///   "workbenchTitle":"工作台",
///   "workbenchUrl":"http://47.110.147.231/hb-trade/"}}
/// ```
///
/// 之前这里写的是蛇形 `server_url` / `api_version` / `maintenance`，
/// 与服务端实际返回**完全对不上**，解码必然失败。
public struct AppConfig: Codable {
    /// 客服/多开账号 id
    public let mulUserId: String?
    /// 充值可选金额
    public let rechargeAmounts: [Int]?
    /// 充值页地址
    public let rechargeUrl: String?
    /// 红包过期小时数，0 = 不过期
    public let redPacketExpireHours: Int?
    /// 是否收取红包手续费
    public let redPacketFeeEnabled: Bool?
    /// SVIP 月费
    public let svipMonthly: Int?
    /// 交易大厅地址
    public let tradeHallUrl: String?
    /// VIP 月费
    public let vipMonthly: Int?
    /// 提现可选金额
    public let withdrawAmounts: [Int]?
    /// 提现页地址
    public let withdrawUrl: String?
    /// 工作台标题
    public let workbenchTitle: String?
    /// 工作台地址
    public let workbenchUrl: String?

    enum CodingKeys: String, CodingKey {
        case mulUserId
        case rechargeAmounts
        case rechargeUrl
        case redPacketExpireHours
        case redPacketFeeEnabled
        case svipMonthly
        case tradeHallUrl
        case vipMonthly
        case withdrawAmounts
        case withdrawUrl
        case workbenchTitle
        case workbenchUrl
    }

    /// 兼容旧调用点：业务 API 根地址。服务端不再下发该字段，
    /// 回落到本地已知的规范入口。
    public var serverUrl: String {
        workbenchUrl ?? "https://api.eaqenw.cn/biz/"
    }

    /// 兼容旧调用点：配置版本号。服务端未下发时固定为 "1.0"。
    public var apiVersion: String {
        "1.0"
    }

    /// 兼容旧调用点：是否维护中。服务端未提供该能力，恒为 false。
    public var maintenance: Bool {
        false
    }

    /// 兼容旧调用点：维护提示语。
    public var maintenanceMsg: String? {
        nil
    }
}

// MARK: - 业务错误

public enum BizError: Error {
    case invalidURL
    case networkError(Error)
    case noData
    case apiError(code: Int, message: String?)
    case decodingError(Error)
    case timeout
    case cancelled
    
    public var errorDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message ?? "Unknown")"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .timeout:
            return "Request timeout"
        case .cancelled:
            return "Request cancelled"
        }
    }
}
