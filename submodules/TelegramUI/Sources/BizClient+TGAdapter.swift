// BizClient+TGAdapter.swift
// 业务 API 客户端 - 为 TG 的网络框架重新设计
//
// 与悟空的 BizClient 不同：
// - 悟空用 Alamofire + callback
// - TG 使用自定义 Signal 响应式框架 + URLSession
// - 这个版本完全适配 TG 的架构

import Foundation
import SwiftSignalKit

/// HTTP 方法
public enum BizHTTPMethod: String {
    case get
    case post
    case delete
}

/// 业务 API 客户端 - 针对 TG 的网络框架
public class BizClient {
    public static let shared = BizClient()
    
    private var urlSession: URLSession
    private var baseURL: String
    
    private init() {
        // 使用 URLSession 而不是 Alamofire
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        self.urlSession = URLSession(configuration: config)
        
        // API 基础地址（可配置）
        if let saved = UserDefaults.standard.string(forKey: "io.openim.biz.api"),
           !saved.isEmpty {
            self.baseURL = saved
        } else {
            self.baseURL = "http://47.110.32.128:11002/biz/"
        }
    }
    
    /// 获取 Business Token
    private func getToken() -> String {
        // 优先读 AppDelegate 中设置的
        if let t = UserDefaults.standard.string(forKey: "businessToken"),
           !t.isEmpty {
            return t
        }
        return ""
    }
    
    /// GET 请求 - 返回 Signal
    public func get<T: Decodable>(
        path: String
    ) -> Signal<T, BizError> {
        return Signal { subscriber in
            self.performRequest(
                path: path,
                method: .get,
                body: nil,
                subscriber: subscriber
            )
        }
    }
    
    /// POST 请求 - 返回 Signal
    public func post<T: Decodable>(
        path: String,
        body: [String: Any]?
    ) -> Signal<T, BizError> {
        return Signal { subscriber in
            var bodyData: Data? = nil
            if let body = body {
                bodyData = try? JSONSerialization.data(withJSONObject: body)
            }
            
            self.performRequest(
                path: path,
                method: .post,
                body: bodyData,
                subscriber: subscriber
            )
        }
    }
    
    /// DELETE 请求 - 返回 Signal
    public func delete<T: Decodable>(
        path: String
    ) -> Signal<T, BizError> {
        return Signal { subscriber in
            self.performRequest(
                path: path,
                method: .delete,
                body: nil,
                subscriber: subscriber
            )
        }
    }
    
    // MARK: - 私有方法
    
    private func performRequest<T: Decodable>(
        path: String,
        method: BizHTTPMethod,
        body: Data?,
        subscriber: Subscriber<T, BizError>
    ) -> Disposable {
        let urlString = baseURL + path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: urlString) else {
            subscriber.putError(.invalidURL)
            return EmptyDisposable
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(getToken(), forHTTPHeaderField: "token")
        request.httpBody = body
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                subscriber.putError(.networkError(error))
                return
            }
            
            guard let data = data else {
                subscriber.putError(.noData)
                return
            }
            
            do {
                let resp = try JSONDecoder().decode(BizResp<T>.self, from: data)
                if resp.code == 0, let result = resp.data {
                    subscriber.putNext(result)
                    subscriber.putCompletion()
                } else {
                    subscriber.putError(.apiError(code: resp.code, message: resp.msg))
                }
            } catch {
                subscriber.putError(.decodingError(error))
            }
        }
        
        task.resume()
        return ActionDisposable { task.cancel() }
    }
    
    /// 配置 API 地址
    public func setBaseURL(_ url: String) {
        self.baseURL = url
        UserDefaults.standard.set(url, forKey: "io.openim.biz.api")
    }
}
// 注：BizResp / BizError 已由 BizModels.swift 统一定义，此处不再重复声明。
