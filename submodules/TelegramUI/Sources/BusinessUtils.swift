// BusinessUtils.swift
// 业务工具库 - 格式化、适配、消息提示等

import Foundation
import UIKit

// MARK: - 格式化工具

public enum FormatUtil {
    
    /// 格式化金额
    public static func formatMoney(_ amount: Double, currency: String = "¥") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return "\(currency)\(formatted)"
        }
        return "\(currency)0.00"
    }
    
    /// 格式化整数（加千分位）
    public static func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
    
    /// 格式化时间（相对时间）
    public static func formatRelativeTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)天前"
        }
        if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        }
        if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        }
        return "刚刚"
    }
    
    /// 格式化文件大小
    public static func formatFileSize(_ bytes: Int64) -> String {
        if bytes < 1024 {
            return "\(bytes)B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.2fKB", Double(bytes) / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.2fMB", Double(bytes) / (1024 * 1024))
        } else {
            return String(format: "%.2fGB", Double(bytes) / (1024 * 1024 * 1024))
        }
    }
}

// MARK: - 屏幕适配

public enum SizeAdapter {
    
    private static let designWidth: CGFloat = 375  // iPhone 基准宽度
    
    public static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    public static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    /// 根据设计稿宽度适配尺寸
    public static func adapt(_ designSize: CGFloat) -> CGFloat {
        return designSize * (screenWidth / designWidth)
    }
    
    /// 获取安全区域底部间距（处理刘海屏）
    public static var safeAreaBottomInset: CGFloat {
        if let window = BizWindowHelper.keyWindow {
            return window.safeAreaInsets.bottom
        }
        return 0
    }
    
    /// 获取状态栏高度
    public static var statusBarHeight: CGFloat {
        BizWindowHelper.statusBarHeight
    }
}

/// MARK: - Window 辅助

/// 统一的 window 查找逻辑，兼容多 Scene，并避免使用已废弃的 API。
enum BizWindowHelper {
    /// 当前 key window
    static var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
            if let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first {
                return activeScene.windows.first(where: { $0.isKeyWindow }) ?? activeScene.windows.first
            }
        }
        return nil
    }
    
    /// 状态栏高度
    static var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.statusBarManager?.statusBarFrame.height ?? 20
            }
        }
        return 20
    }
}

// MARK: - UI 消息提示

public enum UIMessageHelper {
    
    /// 显示 Toast（简单提示）
    public static func showToast(_ message: String, duration: TimeInterval = 2.0) {
        DispatchQueue.main.async {
            guard let window = BizWindowHelper.keyWindow else { return }
            
            let label = UILabel()
            label.text = message
            label.textColor = .white
            label.backgroundColor = UIColor(white: 0, alpha: 0.8)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 14)
            label.layer.cornerRadius = 8
            label.clipsToBounds = true
            label.alpha = 0.9
            
            let maxWidth = window.bounds.width - 40
            let inset: CGFloat = 20
            label.frame = CGRect(x: inset, y: 0, width: maxWidth, height: 44)
            label.sizeToFit()
            label.frame.size.width = min(label.frame.width + 20, maxWidth)
            label.frame.size.height = max(label.frame.height + 16, 44)
            label.center.x = window.center.x
            label.center.y = window.bounds.height - 100
            
            window.addSubview(label)
            
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
        }
    }
    
    /// 显示 Alert
    public static func showAlert(title: String, message: String, okTitle: String = "确定") {
        DispatchQueue.main.async {
            guard let window = BizWindowHelper.keyWindow,
                  let rootViewController = window.rootViewController else {
                return
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: okTitle, style: .default))
            rootViewController.present(alert, animated: true)
        }
    }
    
    /// 显示确认对话框
    public static func showConfirm(
        title: String,
        message: String,
        okTitle: String = "确定",
        cancelTitle: String = "取消",
        onOk: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            guard let window = BizWindowHelper.keyWindow,
                  let rootViewController = window.rootViewController else {
                return
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: okTitle, style: .default) { _ in onOk() })
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - JSON 工具

public enum JsonTool {
    
    /// 对象转 JSON 字符串
    public static func toJsonString(_ object: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// JSON 字符串转对象
    public static func fromJsonString(_ jsonString: String) -> Any? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }
    
    /// 美化 JSON（添加缩进）
    public static func prettyJsonString(_ object: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
