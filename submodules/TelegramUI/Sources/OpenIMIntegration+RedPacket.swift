// OpenIMIntegration+RedPacket.swift (重新实现)
// OpenIM 与红包系统的集成
//
// 职责：
// 1. 监听 OpenIM 消息
// 2. 识别红包消息
// 3. 分发给红包管理器
// 4. 提供便利 API

import Foundation

extension OpenIMIntegration {
    
    /// 注册红包消息处理
    /// 在 AppDelegate 中调用：OpenIMIntegration.shared.registerRedPacketHandler()
    public func registerRedPacketHandler() {
        // 监听 OpenIM 消息接收事件
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenIMMessageReceived"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleOpenIMMessage(notification)
        }
    }
    
    /// 处理 OpenIM 消息
    private func handleOpenIMMessage(_ notification: NSNotification) {
        // 从通知中提取消息内容
        // 消息格式取决于 OpenIM SDK 的实现
        // 这里假设消息在 notification.userInfo["content"] 中
        
        guard let userInfo = notification.userInfo,
              let messageContent = userInfo["content"] as? String else {
            return
        }
        
        // 检查是否是红包消息
        if RedPacketManager.shared.isRedPacketMessage(messageContent) {
            // 交给红包管理器处理
            RedPacketManager.shared.handleRedPacketMessage(messageContent)
        }
    }
    
    /// 便利 API：获取红包通知观察器
    /// 使用方式:
    /// NotificationCenter.default.addObserver(
    ///     forName: OpenIMIntegration.shared.redPacketNotificationName,
    ///     object: nil,
    ///     queue: .main
    /// ) { notification in
    ///     let redPacket = notification.object as? RedPacket
    /// }
    public var redPacketNotificationName: NSNotification.Name {
        return RedPacketManager.shared.redPacketNotification
    }
    
    /// 便利 API：检查消息是否是红包
    public func isRedPacketMessage(_ content: String) -> Bool {
        return RedPacketManager.shared.isRedPacketMessage(content)
    }
    
    /// 便利 API：解析红包
    public func parseRedPacket(_ content: String) -> RedPacket? {
        return RedPacketManager.shared.parseRedPacketMessage(content)
    }
}
