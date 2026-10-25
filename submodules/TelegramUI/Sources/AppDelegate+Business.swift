// AppDelegate+Business.swift
// 业务模块初始化

import Foundation

extension AppDelegate {
    
    /// 初始化业务系统
    /// 在 application(_:didFinishLaunchingWithOptions:) 中调用
    @objc func setupBusinessModule() {
        // 1. 配置业务 API 地址
        let apiUrl = "http://47.110.32.128:11002/biz/"
        BizClient.shared.setBaseURL(apiUrl)
        
        // 2. 初始化设备信息
        _ = BizConstants.deviceUuid
        _ = BizConstants.deviceType
        
        print("🎯 业务系统已初始化")
        print("   API: \(BizConstants.bizApiBaseUrl)")
        print("   Device: \(BizConstants.deviceType)")
        
        // 3. 注册红包消息处理
        OpenIMIntegration.shared.registerRedPacketHandler()
    }
}
