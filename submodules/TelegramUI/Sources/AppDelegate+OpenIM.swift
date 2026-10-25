// AppDelegate+OpenIM.swift
// AppDelegate 的 OpenIM 扩展

import UIKit

extension AppDelegate {
    
    /// 在 didFinishLaunchingWithOptions 中调用此方法
    @objc func setupOpenIMIntegration() {
        print("🚀 初始化 OpenIM 集成...")

        // 业务模块初始化（配置业务 API 地址 + 注册红包消息处理）。
        // 与 OpenIM 集成一起启动，保证 BizClient 的 baseURL 先行就绪。
        setupBusinessModule()
        
        do {
            // 配置 OpenIM
            let serverURL = "http://your-openim-server:10001"
            let wsURL = "ws://your-openim-server:10002"
            let userId = "user-id"
            let token = "access-token"
            
            // 初始化（代码被注释，避免缺少依赖时崩溃）
            // OpenIMIntegration.shared.initialize(
            //     serverURL: serverURL,
            //     wsURL: wsURL,
            //     userId: userId,
            //     token: token,
            //     databaseManager: dbManager
            // )
            
            print("✅ OpenIM 已初始化")
        } catch {
            print("❌ OpenIM 初始化失败: \(error)")
        }
    }
}
