// BizHelper.swift
// TG 侧业务工具函数。
//
// 与悟空 (OUICore) 的 BizHelper 保持同名同语义，便于两边代码对照迁移。
// 这里只包含纯函数工具，不包含依赖 callback 版 BizClient 的 BizAPI，
// 因为 TG 侧的 BizClient 是泛型 Signal 版（见 BizClient+TGAdapter.swift）。

import Foundation
import UIKit

public enum BizHelper {
    /// 任意值转字符串，nil / NSNull 安全。
    public static func str(_ v: Any?) -> String {
        if v == nil || v is NSNull { return "" }
        if let s = v as? String { return s }
        return String(describing: v!)
    }

    /// 任意值转数字，无法解析时返回 0。
    public static func num(_ v: Any?) -> Double {
        if let n = v as? Double { return n }
        if let n = v as? Int { return Double(n) }
        if let n = v as? Int64 { return Double(n) }
        if let n = v as? NSNumber { return n.doubleValue }
        if let s = v as? String {
            let cleaned = s
                .replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let d = Double(cleaned) { return d }
        }
        return 0
    }

    /// 金额格式化，输出 ¥0.00 形式。
    public static func money(_ v: Any?) -> String {
        String(format: "\u{00A5}%.2f", num(v))
    }

    /// 轻量 Toast。
    public static func toast(_ text: String) {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let win = scene.windows.first(where: { $0.isKeyWindow }) else { return }
            let label = UILabel()
            label.text = text
            label.textColor = .white
            label.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            label.font = .systemFont(ofSize: 14)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            win.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: win.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: win.safeAreaLayoutGuide.bottomAnchor, constant: -80),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: win.leadingAnchor, constant: 24),
                label.trailingAnchor.constraint(lessThanOrEqualTo: win.trailingAnchor, constant: -24)
            ])
            label.layoutIfNeeded()
            UIView.animate(withDuration: 0.2, animations: { label.alpha = 1 }) { _ in
                UIView.animate(withDuration: 0.2, delay: 1.4, options: [], animations: { label.alpha = 0 }) { _ in
                    label.removeFromSuperview()
                }
            }
        }
    }

    /// 任意值转字典数组。
    public static func dictArray(_ data: Any?) -> [[String: Any]] {
        if let arr = data as? [[String: Any]] { return arr }
        return []
    }

    /// 任意值转字典。
    public static func dict(_ data: Any?) -> [String: Any] {
        if let d = data as? [String: Any] { return d }
        return [:]
    }
}
