// RedPacketConfigCache.swift
// 红包配置缓存系统

import Foundation

/// 红包配置缓存
public class RedPacketConfigCache {
    public static let shared = RedPacketConfigCache()
    
    private var configCache: [String: Any] = [:]
    private let cacheLock = NSLock()
    private let userDefaults = UserDefaults.standard
    
    private let cacheKeyPrefix = "io.openim.redpacket."
    
    // MARK: - 配置项
    
    /// 红包最大金额
    public var maxAmount: Double {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            if let value = configCache["maxAmount"] as? Double {
                return value
            }
            let defaultValue = 888.0
            configCache["maxAmount"] = defaultValue
            return defaultValue
        }
        set {
            cacheLock.lock()
            configCache["maxAmount"] = newValue
            cacheLock.unlock()
            save()
        }
    }
    
    /// 红包最小金额
    public var minAmount: Double {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            if let value = configCache["minAmount"] as? Double {
                return value
            }
            let defaultValue = 0.01
            configCache["minAmount"] = defaultValue
            return defaultValue
        }
        set {
            cacheLock.lock()
            configCache["minAmount"] = newValue
            cacheLock.unlock()
            save()
        }
    }
    
    /// 红包领取超时时间（秒）
    public var claimTimeout: Int {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            if let value = configCache["claimTimeout"] as? Int {
                return value
            }
            let defaultValue = 3600  // 1小时
            configCache["claimTimeout"] = defaultValue
            return defaultValue
        }
        set {
            cacheLock.lock()
            configCache["claimTimeout"] = newValue
            cacheLock.unlock()
            save()
        }
    }
    
    /// 红包有效期（天数）
    public var validityPeriod: Int {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            if let value = configCache["validityPeriod"] as? Int {
                return value
            }
            let defaultValue = 30
            configCache["validityPeriod"] = defaultValue
            return defaultValue
        }
        set {
            cacheLock.lock()
            configCache["validityPeriod"] = newValue
            cacheLock.unlock()
            save()
        }
    }
    
    // MARK: - 缓存操作
    
    /// 从 UserDefaults 加载缓存
    public func load() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        let defaults = UserDefaults.standard
        let keys = ["maxAmount", "minAmount", "claimTimeout", "validityPeriod"]
        
        for key in keys {
            if let value = defaults.object(forKey: cacheKeyPrefix + key) {
                configCache[key] = value
            }
        }
    }
    
    /// 保存缓存到 UserDefaults
    private func save() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        for (key, value) in configCache {
            userDefaults.set(value, forKey: cacheKeyPrefix + key)
        }
        userDefaults.synchronize()
    }
    
    /// 清除缓存
    public func clear() {
        cacheLock.lock()
        configCache.removeAll()
        cacheLock.unlock()
        
        let keys = ["maxAmount", "minAmount", "claimTimeout", "validityPeriod"]
        for key in keys {
            userDefaults.removeObject(forKey: cacheKeyPrefix + key)
        }
        userDefaults.synchronize()
    }
    
    // MARK: - 初始化
    
    private init() {
        load()
    }
}
