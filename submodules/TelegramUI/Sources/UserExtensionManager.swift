// UserExtensionManager.swift
// 用户扩展字段处理系统

import Foundation

/// 用户扩展字段管理器
public class UserExtensionManager {
    public static let shared = UserExtensionManager()
    
    private var cache: [String: [String: Any]] = [:]
    private let cacheLock = NSLock()
    
    // MARK: - 解析
    
    /// 解析用户扩展字段 JSON
    public func parseExtension(_ jsonString: String?) -> [String: Any] {
        guard let jsonString = jsonString,
              !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
    
    /// 读取字符串值（支持多个 key 别名）
    public func readString(_ dict: [String: Any], keys: String...) -> String {
        for key in keys {
            if let value = dict[key] as? String, !value.isEmpty {
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let value = dict[key] as? NSNumber {
                return value.stringValue
            }
        }
        return ""
    }
    
    /// 读取整数值
    public func readInt(_ dict: [String: Any], keys: String...) -> Int {
        for key in keys {
            if let value = dict[key] as? Int {
                return value
            }
            if let value = dict[key] as? NSNumber {
                return value.intValue
            }
        }
        return 0
    }
    
    // MARK: - 号码等级
    
    /// 提取号码等级
    public func extractNumberLevel(_ exJson: String?) -> String {
        let dict = parseExtension(exJson)
        return readString(dict, keys: "number_level", "numberLevel", "number_cate", "numberCate", "show_level", "showLevel", "grade", "level", "lv")
    }
    
    // MARK: - 展示号码
    
    /// 提取展示号码
    public func extractShowNumber(_ exJson: String?) -> String {
        let dict = parseExtension(exJson)
        return readString(dict, keys: "show_number", "showNumber", "number", "lianghao", "pretty_number")
    }
    
    /// 获取显示用户 ID（优先展示号，不然用原 ID）
    public func displayUserId(exJson: String?, fallbackUserId: String?) -> String {
        let showNumber = extractShowNumber(exJson)
        if !showNumber.isEmpty {
            return showNumber
        }
        return fallbackUserId ?? ""
    }
    
    // MARK: - VIP 信息
    
    /// 提取 VIP 等级
    public func extractVipLevel(_ exJson: String?) -> Int {
        let dict = parseExtension(exJson)
        return readInt(dict, keys: "vip_level", "vipLevel", "vip", "level")
    }
    
    /// 提取 VIP 过期时间
    public func extractVipExpire(_ exJson: String?) -> String {
        let dict = parseExtension(exJson)
        return readString(dict, keys: "vip_expire", "vipExpire", "expire_time", "expireTime")
    }
    
    // MARK: - 缓存
    
    /// 缓存用户扩展信息
    public func cacheExtension(userId: String, exJson: String?) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        if let exJson = exJson {
            cache[userId] = parseExtension(exJson)
        } else {
            cache.removeValue(forKey: userId)
        }
    }
    
    /// 从缓存读取
    public func getCachedExtension(userId: String) -> [String: Any]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return cache[userId]
    }
    
    /// 清除缓存
    public func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cache.removeAll()
    }
}
