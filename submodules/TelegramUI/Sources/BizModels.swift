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

public struct RedPacketInfo: Codable {
    public let id: Int64
    public let message: String           // 祝福语
    public let money: String             // 金额
    public let groupId: String           // 群组ID
    public let toUserId: String?         // 接收者（专属红包）
    public let activityType: Int         // 2=群红包, 3=专属红包
    public let activityScope: Int        // 1=P2P, 2=群
    
    enum CodingKeys: String, CodingKey {
        case id
        case message
        case money
        case groupId = "group_id"
        case toUserId = "to_user_id"
        case activityType = "activity_type"
        case activityScope = "activity_scope"
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

public struct AppConfig: Codable {
    public let serverUrl: String
    public let apiVersion: String
    public let maintenance: Bool
    public let maintenanceMsg: String?
    
    enum CodingKeys: String, CodingKey {
        case serverUrl = "server_url"
        case apiVersion = "api_version"
        case maintenance
        case maintenanceMsg = "maintenance_msg"
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
