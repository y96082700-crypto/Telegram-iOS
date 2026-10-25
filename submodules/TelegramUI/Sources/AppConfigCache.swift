// AppConfigCache.swift
// 应用配置缓存管理

import Foundation

/// 应用配置缓存管理器
public class AppConfigCache {
    public static let shared = AppConfigCache()
    
    private var cache: [String: Any] = [:]
    private let cacheLock = NSLock()
    private let userDefaults = UserDefaults.standard
    
    private let cacheKeyPrefix = "io.openim.config."
    
    // MARK: - 配置项
    
    /// API 服务器地址
    public var apiServerUrl: String {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            if let value = cache["apiServerUrl"] as? String {
                return value
            }
            return "http://47.110.32.128:11002/biz/"
        }
        set {
            cacheLock.lock()
            cache["apiServerUrl"] = newValue
            cacheLock.unlock()
            save()
        }
    }
    
    /// API 版本
    public var apiVersion: String {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            if let value = cache["apiVersion"] as? String {
                return value
            }
            return "1.0"
        }
        set {
            cacheLock.lock()
            cache["apiVersion"] = newValue
            cacheLock.unlock()
            save()
        }
    }
    
    /// 是否维护中
    public var isMaintenance: Bool {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            if let value = cache["isMaintenance"] as? Bool {
                return value
            }
            return false
        }
        set {
            cacheLock.lock()
            cache["isMaintenance"] = newValue
            cacheLock.unlock()
            save()
        }
    }
    
    /// 维护消息
    public var maintenanceMessage: String {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            if let value = cache["maintenanceMessage"] as? String {
                return value
            }
            return ""
        }
        set {
            cacheLock.lock()
            cache["maintenanceMessage"] = newValue
            cacheLock.unlock()
            save()
        }
    }
    
    /// 更新可用性检查间隔（秒）
    public var updateCheckInterval: Int {
        get {
            cacheLock.lock()
            defer { cacheLock.unlock() }
            if let value = cache["updateCheckInterval"] as? Int {
                return value
            }
            return 3600  // 1小时
        }
        set {
            cacheLock.lock()
            cache["updateCheckInterval"] = newValue
            cacheLock.unlock()
            save()
        }
    }
    
    /// 更新配置
    public func updateFromResponse(_ response: AppConfig) {
        cacheLock.lock()
        cache["apiServerUrl"] = response.serverUrl
        cache["apiVersion"] = response.apiVersion
        cache["isMaintenance"] = response.maintenance
        cache["maintenanceMessage"] = response.maintenanceMsg ?? ""
        cacheLock.unlock()
        save()
    }
    
    // MARK: - 缓存操作
    
    /// 从 UserDefaults 加载
    public func load() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        let defaults = UserDefaults.standard
        let keys = ["apiServerUrl", "apiVersion", "isMaintenance", "maintenanceMessage", "updateCheckInterval"]
        
        for key in keys {
            if let value = defaults.object(forKey: cacheKeyPrefix + key) {
                cache[key] = value
            }
        }
    }
    
    /// 保存到 UserDefaults
    private func save() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        for (key, value) in cache {
            userDefaults.set(value, forKey: cacheKeyPrefix + key)
        }
        userDefaults.synchronize()
    }
    
    /// 清除缓存
    public func clear() {
        cacheLock.lock()
        cache.removeAll()
        cacheLock.unlock()
        
        let keys = ["apiServerUrl", "apiVersion", "isMaintenance", "maintenanceMessage", "updateCheckInterval"]
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
