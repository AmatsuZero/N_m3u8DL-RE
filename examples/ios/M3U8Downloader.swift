//
//  M3U8Downloader.swift
//  N_m3u8DL-RE iOS Example
//
//  Swift wrapper for N_m3u8DL_RE_Core library
//

import Foundation

/// 下载进度回调
public typealias DownloadProgressHandler = (Int, Int64, Int64) -> Void

/// 下载完成回调
public typealias DownloadCompletionHandler = (Bool, String?) -> Void

/// M3U8 下载器
public class M3U8Downloader {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = M3U8Downloader()
    
    private let downloadQueue = DispatchQueue(label: "com.n-m3u8dl-re.download")
    private var isCancelled = false
    private var progressHandler: DownloadProgressHandler?
    private var completionHandler: DownloadCompletionHandler?
    
    // MARK: - Lifecycle
    
    private init() {
        // 初始化库
        let result = m3u8dl_init()
        if result != 0 {
            print("[M3U8Downloader] Failed to initialize library: \(result)")
        }
    }
    
    deinit {
        cancel()
    }
    
    // MARK: - Public Methods
    
    /// 开始下载
    /// - Parameters:
    ///   - url: M3U8 播放列表 URL
    ///   - outputPath: 输出文件路径
    ///   - onProgress: 进度回调（可选）
    ///   - onCompletion: 完成回调
    public func download(
        url: String,
        outputPath: String,
        onProgress: DownloadProgressHandler? = nil,
        onCompletion: @escaping DownloadCompletionHandler
    ) {
        guard !url.isEmpty else {
            onCompletion(false, nil)
            return
        }
        
        guard !outputPath.isEmpty else {
            onCompletion(false, nil)
            return
        }
        
        self.progressHandler = onProgress
        self.completionHandler = onCompletion
        self.isCancelled = false
        
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 启动下载
            let result = url.withCString { urlPtr in
                outputPath.withCString { pathPtr in
                    m3u8dl_download(urlPtr, pathPtr) { result, outputPtr in
                        DispatchQueue.main.async {
                            if let handler = self.completionHandler {
                                if result == 0 {
                                    let output = outputPtr != nil ? String(cString: outputPtr!) : outputPath
                                    handler(true, output)
                                } else {
                                    handler(false, nil)
                                }
                            }
                        }
                    }
                }
            }
            
            if result != 0 {
                DispatchQueue.main.async {
                    self.completionHandler?(false, nil)
                }
                return
            }
            
            // 监控进度
            while !self.isCancelled {
                let progress = Int(m3u8dl_get_progress())
                
                DispatchQueue.main.async {
                    // TODO: 获取实际的下载字节数
                    self.progressHandler?(progress, 0, 0)
                }
                
                if progress >= 100 {
                    break
                }
                
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    /// 取消当前下载
    public func cancel() {
        isCancelled = true
        m3u8dl_cancel()
    }
    
    /// 获取当前下载进度 (0-100)
    public var currentProgress: Int {
        return Int(m3u8dl_get_progress())
    }
    
    /// 获取库版本
    public var libraryVersion: String {
        guard let versionPtr = m3u8dl_get_version() else {
            return "Unknown"
        }
        let version = String(cString: versionPtr)
        m3u8dl_free_string(versionPtr)
        return version
    }
    
    /// 获取 API 版本
    public var apiVersion: String {
        let version = m3u8dl_get_api_version()
        let major = (version >> 16) & 0xFF
        let minor = (version >> 8) & 0xFF
        let patch = version & 0xFF
        return "\(major).\(minor).\(patch)"
    }
}

// MARK: - Usage Example

/*
 // 使用示例
 
 let downloader = M3U8Downloader.shared
 
 downloader.download(
     url: "https://example.com/playlist.m3u8",
     outputPath: "/path/to/output.mp4",
     onProgress: { progress, downloaded, total in
         print("下载进度: \(progress)%")
     },
     onCompletion: { success, output in
         if success {
             print("下载完成: \(output ?? "")")
         } else {
             print("下载失败")
         }
     }
 )
 
 // 取消下载
 // downloader.cancel()
 
 // 获取版本信息
 print("Library Version: \(downloader.libraryVersion)")
 print("API Version: \(downloader.apiVersion)")
 */
