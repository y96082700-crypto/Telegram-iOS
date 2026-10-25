// FileManager+Business.swift
// 文件操作系统

import Foundation

extension FileManager {
    
    /// 业务数据目录
    public static var businessDataDirectory: URL? {
        guard let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let bizDir = documentDir.appendingPathComponent("BusinessData")
        
        try? FileManager.default.createDirectory(at: bizDir, withIntermediateDirectories: true)
        return bizDir
    }
    
    /// 红包缓存目录
    public static var redPacketCacheDirectory: URL? {
        guard let businessDir = businessDataDirectory else { return nil }
        let cacheDir = businessDir.appendingPathComponent("RedPackets")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }
    
    /// 保存文件
    public static func saveFile(_ data: Data, filename: String, directory: URL?) -> URL? {
        guard let directory = directory else { return nil }
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("❌ 文件保存失败: \(error)")
            return nil
        }
    }
    
    /// 读取文件
    public static func readFile(filename: String, directory: URL?) -> Data? {
        guard let directory = directory else { return nil }
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            print("❌ 文件读取失败: \(error)")
            return nil
        }
    }
    
    /// 删除文件
    public static func deleteFile(filename: String, directory: URL?) -> Bool {
        guard let directory = directory else { return false }
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            print("❌ 文件删除失败: \(error)")
            return false
        }
    }
}

/// 多线程下载器
public class MultiThreadDownloader: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    
    public static let shared = MultiThreadDownloader()
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    private var downloadTasks: [URL: URLSessionDownloadTask] = [:]
    private var progressCallbacks: [URL: (Progress) -> Void] = [:]
    private let taskLock = NSLock()
    
    // MARK: - 下载
    
    /// 下载文件
    public func downloadFile(
        from url: URL,
        onProgress: @escaping (Progress) -> Void,
        completion: @escaping (URL?, Error?) -> Void
    ) {
        let downloadTask = urlSession.downloadTask(with: url) { tempURL, response, error in
            defer {
                self.taskLock.lock()
                self.downloadTasks.removeValue(forKey: url)
                self.progressCallbacks.removeValue(forKey: url)
                self.taskLock.unlock()
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "Download", code: -1))
                }
                return
            }
            
            // 保存到缓存目录
            if let filename = response?.suggestedFilename ?? url.lastPathComponent,
               let fileData = try? Data(contentsOf: tempURL),
               let saveURL = FileManager.saveFile(
                   fileData,
                   filename: filename,
                   directory: FileManager.businessDataDirectory
               ) {
                DispatchQueue.main.async {
                    completion(saveURL, nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion(tempURL, nil)
                }
            }
        }
        
        taskLock.lock()
        downloadTasks[url] = downloadTask
        progressCallbacks[url] = onProgress
        taskLock.unlock()
        
        downloadTask.resume()
    }
    
    /// 取消下载
    public func cancelDownload(for url: URL) {
        taskLock.lock()
        if let task = downloadTasks[url] {
            task.cancel()
            downloadTasks.removeValue(forKey: url)
            progressCallbacks.removeValue(forKey: url)
        }
        taskLock.unlock()
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // 由 completionHandler 处理
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let url = downloadTask.originalRequest?.url else { return }
        
        taskLock.lock()
        let callback = progressCallbacks[url]
        taskLock.unlock()
        
        let progress = Progress()
        progress.totalUnitCount = totalBytesExpectedToWrite
        progress.completedUnitCount = totalBytesWritten
        
        DispatchQueue.main.async {
            callback?(progress)
        }
    }
}
