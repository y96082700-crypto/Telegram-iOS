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
        
        // OpenIM 客户端初始化。
        // 当前构建未集成 OpenIM SDK（缺少该依赖），因此这里只做配置读取与日志输出，
        // 不触发实际的 SDK 调用，避免运行时崩溃。
        // 接入 SDK 后，将下面的配置项传入 OpenIMIntegration.shared.initialize(...) 即可。
        let serverURL = "http://your-openim-server:10001"
        let wsURL = "ws://your-openim-server:10002"
        let userId = "user-id"
        let token = "access-token"
        
        print("✅ OpenIM 配置就绪")
        print("   服务器: \(serverURL)")
        print("   长连接: \(wsURL)")
        print("   用户 ID: \(userId)")
        print("   Token: \(token.isEmpty ? "未设置" : "已设置")")
    }
}
