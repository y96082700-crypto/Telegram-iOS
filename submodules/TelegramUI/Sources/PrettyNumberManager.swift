// PrettyNumberManager.swift
// 漂亮号（虚拟号）系统

import Foundation
import UIKit

/// 漂亮号管理器
public class PrettyNumberManager {
    public static let shared = PrettyNumberManager()
    
    private var numberCache: [String: PrettyNumberInfo] = [:]
    private let cacheLock = NSLock()
    
    // MARK: - 数据结构
    
    public struct PrettyNumberInfo {
        public let number: String
        public let level: String        // 等级标签
        public let badge: UIImage?      // 徽章图片
        public let vipLevel: Int
        
        public init(number: String, level: String, badge: UIImage? = nil, vipLevel: Int = 0) {
            self.number = number
            self.level = level
            self.badge = badge
            self.vipLevel = vipLevel
        }
    }
    
    // MARK: - 号码处理
    
    /// 提取和格式化号码
    public func formatNumber(_ exJson: String?) -> String {
        let manager = UserExtensionManager.shared
        return manager.extractShowNumber(exJson)
    }
    
    /// 获取号码等级标签
    public func getNumberLevel(_ exJson: String?) -> String {
        let manager = UserExtensionManager.shared
        let level = manager.extractNumberLevel(exJson)
        return formatLevelLabel(level)
    }
    
    // MARK: - 等级和标签
    
    /// 格式化等级标签（如 "1" -> "铂金会员"）
    private func formatLevelLabel(_ levelCode: String) -> String {
        let levelMap: [String: String] = [
            "0": "标准用户",
            "1": "银牌会员",
            "2": "金牌会员",
            "3": "铂金会员",
            "4": "钻石会员",
        ]
        return levelMap[levelCode] ?? ""
    }
    
    /// 获取等级对应的颜色
    public func getLevelColor(_ levelCode: String) -> UIColor {
        switch levelCode {
        case "1":
            return UIColor(rgb: 0xC0C0C0)  // 银色
        case "2":
            return UIColor(rgb: 0xFFD700)  // 金色
        case "3":
            return UIColor(rgb: 0xE5E4E1)  // 铂金色
        case "4":
            return UIColor(rgb: 0xB9F2FF)  // 钻石蓝
        default:
            return UIColor.gray
        }
    }
    
    // MARK: - 徽章
    
    /// 获取号码徽章图片
    public func getNumberBadge(_ exJson: String?) -> UIImage? {
        let manager = UserExtensionManager.shared
        let number = manager.extractShowNumber(exJson)
        
        if !number.isEmpty {
            // 返回预定义的漂亮号徽章
            return generateNumberBadge(number)
        }
        return nil
    }
    
    /// 生成号码徽章（简单示例：使用纯色圆形）
    private func generateNumberBadge(_ number: String) -> UIImage? {
        let size: CGFloat = 20
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            UIColor(rgb: 0xFF6B6B).setFill()  // 红色
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
            
            // 绘制文字
            let text = "☆"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: UIColor.white,
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - VIP 徽章
    
    /// 获取 VIP 徽章
    public func getVipBadge(_ exJson: String?) -> UIImage? {
        let manager = UserExtensionManager.shared
        let vipLevel = manager.extractVipLevel(exJson)
        
        if vipLevel > 0 {
            return generateVipBadge(level: vipLevel)
        }
        return nil
    }
    
    /// 生成 VIP 徽章
    private func generateVipBadge(level: Int) -> UIImage? {
        let size: CGFloat = 20
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            // VIP 背景（黄色）
            UIColor(rgb: 0xFFD700).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
            
            // VIP 文字
            let text = "V"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: UIColor.white,
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - 缓存
    
    public func cacheNumberInfo(_ userId: String, info: PrettyNumberInfo) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        numberCache[userId] = info
    }
    
    public func getCachedNumberInfo(_ userId: String) -> PrettyNumberInfo? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return numberCache[userId]
    }
}

// MARK: - 扩展

extension UIColor {
    convenience init(rgb: Int) {
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
