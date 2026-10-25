// BizConstants.swift
// 业务系统的配置常量和设备信息
//
// 基于悟空的设计，为 TG 环保

import Foundation
import UIKit

public enum BizConstants {
    
    // MARK: - API 配置
    
    /// 业务 API 基础 URL
    public static var bizApiBaseUrl: String {
        if let saved = UserDefaults.standard.string(forKey: "io.openim.biz.api"),
           !saved.isEmpty {
            return saved
        }
        return "http://47.110.32.128:11002/biz/"
    }
    
    /// 业务服务器地址
    public static var businessServer: String {
        get {
            UserDefaults.standard.string(forKey: "io.openim.business.server") ?? "47.110.32.128"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "io.openim.business.server")
        }
    }
    
    // MARK: - 设备信息
    
    /// Device UUID（设备唯一标识）
    public static var deviceUuid: String {
        if let saved = UserDefaults.standard.string(forKey: "io.openim.device.uuid"),
           !saved.isEmpty {
            return saved
        }
        
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(uuid, forKey: "io.openim.device.uuid")
        UserDefaults.standard.synchronize()
        return uuid
    }
    
    /// Device Type（设备型号，如 iPhone14,2）
    public static var deviceType: String {
        var sys = utsname()
        uname(&sys)
        let mirror = Mirror(reflecting: sys.machine)
        let code = mirror.children.reduce(into: "") { acc, el in
            guard let v = el.value as? Int8, v != 0 else { return }
            acc.append(String(UnicodeScalar(UInt8(v))))
        }
        return code.isEmpty ? UIDevice.current.model : code
    }
    
    // MARK: - Token 管理
    
    /// Business Token（业务会话令牌）
    public static var businessToken: String? {
        get {
            UserDefaults.standard.string(forKey: "businessToken")
        }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: "businessToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "businessToken")
            }
            UserDefaults.standard.synchronize()
        }
    }
}
