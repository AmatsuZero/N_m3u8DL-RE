//
//  M3U8Downloader.swift
//  M3U8DownloaderKit
//
//  高级 Swift 包装层，封装 C API 接口
//  符合 Swift 6 并发模型，使用 async/await
//

import Foundation
import M3U8DownloaderKit_C

// MARK: - M3U8Downloader

/// M3U8/HLS/DASH 流媒体下载器
///
/// 这是一个线程安全的下载器类，提供异步 API 用于解析和下载流媒体内容。
///
/// ## 基本用法
///
/// ```swift
/// let downloader = M3U8Downloader()
///
/// // 解析流信息
/// let streams = try await downloader.parse(url: "https://example.com/playlist.m3u8")
///
/// // 下载最高质量
/// let result = try await downloader.download(
///     url: "https://example.com/playlist.m3u8",
///     to: "/path/to/output.mp4"
/// )
/// ```
///
/// ## 进度监控
///
/// ```swift
/// for await progress in downloader.progressStream {
///     print("下载进度: \(progress.percentage)%")
/// }
/// ```
public final class M3U8Downloader: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// 内部实例 ID
    private var instanceId: m3u8dl_instance_t
    
    /// 是否已释放
    private var isDisposed = false
    
    /// 锁保护状态
    private let lock = NSLock()
    
    /// 进度回调存储
    private var progressHandler: ((DownloadProgress) -> Void)?
    
    /// 完成回调存储
    private var completionHandler: ((DownloadResult) -> Void)?
    
    /// 日志回调存储
    private var logHandler: ((LogLevel, String) -> Void)?
    
    /// 进度流的 continuation
    private var progressContinuation: AsyncStream<DownloadProgress>.Continuation?
    
    // MARK: - Static Properties
    
    /// 共享的回调管理器
    /// 使用 nonisolated(unsafe) 因为此属性通过外部锁机制保护
    nonisolated(unsafe) private static var callbackManager = CallbackManager()
    
    /// 全局实例映射 (线程安全，通过 instancesLock 保护)
    /// 使用 nonisolated(unsafe) 因为访问受 instancesLock 保护
    nonisolated(unsafe) private static var instances: [m3u8dl_instance_t: M3U8Downloader] = [:]
    private static let instancesLock = NSLock()
    
    // MARK: - Initialization
    
    /// 创建下载器实例
    ///
    /// - Parameter configuration: 下载器配置，传入 nil 使用默认配置
    /// - Throws: `M3U8Error.initializationFailed` 如果初始化失败
    public init(configuration: Configuration? = nil) throws {
        // 设置全局回调（仅首次）
        Self.setupGlobalCallbacks()
        
        let configJson: String?
        if let config = configuration {
            let encoder = JSONEncoder()
            configJson = String(data: try encoder.encode(config), encoding: .utf8)
        } else {
            configJson = nil
        }
        
        let id = m3u8dl_init(configJson)
        guard id > 0 else {
            throw M3U8Error.initializationFailed
        }
        
        self.instanceId = id
        
        // 注册实例
        Self.registerInstance(self)
    }
    
    deinit {
        dispose()
    }
    
    // MARK: - Instance Management
    
    private static func registerInstance(_ instance: M3U8Downloader) {
        instancesLock.lock()
        defer { instancesLock.unlock() }
        instances[instance.instanceId] = instance
    }
    
    private static func unregisterInstance(_ instanceId: m3u8dl_instance_t) {
        instancesLock.lock()
        defer { instancesLock.unlock() }
        instances.removeValue(forKey: instanceId)
    }
    
    private static func getInstance(for id: m3u8dl_instance_t) -> M3U8Downloader? {
        instancesLock.lock()
        defer { instancesLock.unlock() }
        return instances[id]
    }
    
    // MARK: - Global Callbacks Setup
    
    /// 回调是否已设置（通过 callbacksSetupLock 保护）
    nonisolated(unsafe) private static var callbacksSetup = false
    private static let callbacksSetupLock = NSLock()
    
    private static func setupGlobalCallbacks() {
        callbacksSetupLock.lock()
        defer { callbacksSetupLock.unlock() }
        
        guard !callbacksSetup else { return }
        callbacksSetup = true
        
        // 设置进度回调
        m3u8dl_set_progress_callback { instanceId, percentage, statusJson in
            guard let statusJson = statusJson else { return }
            let jsonString = String(cString: statusJson)
            
            if let instance = M3U8Downloader.getInstance(for: instanceId) {
                instance.handleProgress(percentage: Int(percentage), statusJson: jsonString)
            }
        }
        
        // 设置完成回调
        m3u8dl_set_completion_callback { instanceId, success, resultJson in
            guard let resultJson = resultJson else { return }
            let jsonString = String(cString: resultJson)
            
            if let instance = M3U8Downloader.getInstance(for: instanceId) {
                instance.handleCompletion(success: success != 0, resultJson: jsonString)
            }
        }
        
        // 设置日志回调
        m3u8dl_set_log_callback { level, message in
            guard let message = message else { return }
            let logLevel = LogLevel(rawValue: Int(level.rawValue)) ?? .info
            let messageString = String(cString: message)
            
            // 分发到所有实例
            M3U8Downloader.instancesLock.lock()
            let allInstances = Array(M3U8Downloader.instances.values)
            M3U8Downloader.instancesLock.unlock()
            
            for instance in allInstances {
                instance.handleLog(level: logLevel, message: messageString)
            }
        }
    }
    
    // MARK: - Callback Handlers
    
    private func handleProgress(percentage: Int, statusJson: String) {
        guard let data = statusJson.data(using: .utf8),
              let progress = try? JSONDecoder().decode(DownloadProgress.self, from: data) else {
            return
        }
        
        progressHandler?(progress)
        progressContinuation?.yield(progress)
    }
    
    private func handleCompletion(success: Bool, resultJson: String) {
        guard let data = resultJson.data(using: .utf8),
              let result = try? JSONDecoder().decode(DownloadResult.self, from: data) else {
            return
        }
        
        completionHandler?(result)
    }
    
    private func handleLog(level: LogLevel, message: String) {
        logHandler?(level, message)
    }
    
    // MARK: - Public API
    
    /// 解析 M3U8/DASH URL，获取可用流信息
    ///
    /// - Parameter url: 流媒体 URL
    /// - Returns: 解析结果，包含所有可用流信息
    /// - Throws: `M3U8Error` 如果解析失败
    ///
    /// ## 示例
    ///
    /// ```swift
    /// let result = try await downloader.parse(url: "https://example.com/playlist.m3u8")
    /// for stream in result.streams {
    ///     print("流: \(stream.type) - \(stream.resolution ?? "N/A")")
    /// }
    /// ```
    public func parse(url: String) async throws -> ParseResult {
        try checkDisposed()
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [instanceId] in
                let resultPtr = m3u8dl_parse(instanceId, url)
                defer {
                    if let ptr = resultPtr {
                        m3u8dl_free_string(ptr)
                    }
                }
                
                guard let ptr = resultPtr else {
                    continuation.resume(throwing: M3U8Error.parseFailed(reason: "No result returned"))
                    return
                }
                
                let jsonString = String(cString: ptr)
                guard let data = jsonString.data(using: .utf8) else {
                    continuation.resume(throwing: M3U8Error.parseFailed(reason: "Invalid JSON encoding"))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(ParseResult.self, from: data)
                    if result.success {
                        continuation.resume(returning: result)
                    } else {
                        continuation.resume(throwing: M3U8Error.parseFailed(reason: result.errorMessage ?? "Unknown error"))
                    }
                } catch {
                    continuation.resume(throwing: M3U8Error.parseFailed(reason: error.localizedDescription))
                }
            }
        }
    }
    
    /// 下载流媒体内容
    ///
    /// - Parameters:
    ///   - url: 流媒体 URL
    ///   - outputPath: 输出文件路径
    ///   - options: 下载选项
    /// - Returns: 下载结果
    /// - Throws: `M3U8Error` 如果下载失败
    ///
    /// ## 示例
    ///
    /// ```swift
    /// let result = try await downloader.download(
    ///     url: "https://example.com/playlist.m3u8",
    ///     to: "/path/to/output.mp4",
    ///     options: .init(autoSelectBestQuality: true)
    /// )
    /// print("下载完成: \(result.outputFile ?? "N/A")")
    /// ```
    public func download(
        url: String,
        to outputPath: String,
        options: DownloadOptions = .default
    ) async throws -> DownloadResult {
        try checkDisposed()
        
        let request = DownloadRequest(
            url: url,
            outputPath: outputPath,
            decryptionKeys: options.decryptionKeys,
            customHeaders: options.customHeaders,
            autoSelectBestQuality: options.autoSelectBestQuality
        )
        
        let encoder = JSONEncoder()
        let requestData = try encoder.encode(request)
        guard let requestJson = String(data: requestData, encoding: .utf8) else {
            throw M3U8Error.invalidParameter(name: "request")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [instanceId] in
                let resultPtr = m3u8dl_download(instanceId, requestJson)
                defer {
                    if let ptr = resultPtr {
                        m3u8dl_free_string(ptr)
                    }
                }
                
                guard let ptr = resultPtr else {
                    continuation.resume(throwing: M3U8Error.downloadFailed(reason: "No result returned"))
                    return
                }
                
                let jsonString = String(cString: ptr)
                guard let data = jsonString.data(using: .utf8) else {
                    continuation.resume(throwing: M3U8Error.downloadFailed(reason: "Invalid JSON encoding"))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(DownloadResult.self, from: data)
                    if result.success {
                        continuation.resume(returning: result)
                    } else {
                        continuation.resume(throwing: M3U8Error.downloadFailed(reason: result.errorMessage ?? "Unknown error"))
                    }
                } catch {
                    continuation.resume(throwing: M3U8Error.downloadFailed(reason: error.localizedDescription))
                }
            }
        }
    }
    
    /// 异步下载，支持进度流
    ///
    /// - Parameters:
    ///   - url: 流媒体 URL
    ///   - outputPath: 输出文件路径
    ///   - options: 下载选项
    /// - Returns: 下载任务，可通过 `progressStream` 获取进度
    public func downloadAsync(
        url: String,
        to outputPath: String,
        options: DownloadOptions = .default
    ) throws -> DownloadTask {
        try checkDisposed()
        
        let request = DownloadRequest(
            url: url,
            outputPath: outputPath,
            decryptionKeys: options.decryptionKeys,
            customHeaders: options.customHeaders,
            autoSelectBestQuality: options.autoSelectBestQuality
        )
        
        let encoder = JSONEncoder()
        let requestData = try encoder.encode(request)
        guard let requestJson = String(data: requestData, encoding: .utf8) else {
            throw M3U8Error.invalidParameter(name: "request")
        }
        
        let result = m3u8dl_download_async(instanceId, requestJson)
        guard result == 0 else {
            throw M3U8Error.downloadFailed(reason: "Failed to start async download")
        }
        
        return DownloadTask(downloader: self, instanceId: instanceId)
    }
    
    /// 取消当前下载
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isDisposed else { return }
        m3u8dl_cancel(instanceId)
    }
    
    /// 释放下载器资源
    public func dispose() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isDisposed else { return }
        isDisposed = true
        
        progressContinuation?.finish()
        progressContinuation = nil
        
        Self.unregisterInstance(instanceId)
        m3u8dl_dispose(instanceId)
    }
    
    /// 获取进度流
    public var progressStream: AsyncStream<DownloadProgress> {
        AsyncStream { continuation in
            self.progressContinuation = continuation
            
            continuation.onTermination = { @Sendable _ in
                // 清理
            }
        }
    }
    
    /// 设置进度回调
    ///
    /// - Parameter handler: 进度回调闭包
    public func onProgress(_ handler: @escaping @Sendable (DownloadProgress) -> Void) {
        self.progressHandler = handler
    }
    
    /// 设置日志回调
    ///
    /// - Parameter handler: 日志回调闭包
    public func onLog(_ handler: @escaping @Sendable (LogLevel, String) -> Void) {
        self.logHandler = handler
    }
    
    // MARK: - Feature Query
    
    /// 检查功能是否支持
    ///
    /// - Parameter feature: 功能名称
    /// - Returns: 是否支持
    public func isFeatureSupported(_ feature: Feature) -> Bool {
        guard !isDisposed else { return false }
        return m3u8dl_is_feature_supported(instanceId, feature.rawValue) != 0
    }
    
    /// 获取可用的视频处理器列表
    ///
    /// - Returns: 处理器列表
    public func getProcessors() throws -> [Processor] {
        try checkDisposed()
        
        let resultPtr = m3u8dl_get_processors(instanceId)
        defer {
            if let ptr = resultPtr {
                m3u8dl_free_string(ptr)
            }
        }
        
        guard let ptr = resultPtr else {
            throw M3U8Error.internalError(reason: "Failed to get processors")
        }
        
        let jsonString = String(cString: ptr)
        guard let data = jsonString.data(using: .utf8) else {
            throw M3U8Error.internalError(reason: "Invalid JSON encoding")
        }
        
        return try JSONDecoder().decode([Processor].self, from: data)
    }
    
    /// 获取库版本信息
    ///
    /// - Returns: 版本信息
    public static func getVersion() -> VersionInfo? {
        let resultPtr = m3u8dl_get_version()
        defer {
            if let ptr = resultPtr {
                m3u8dl_free_string(ptr)
            }
        }
        
        guard let ptr = resultPtr else { return nil }
        
        let jsonString = String(cString: ptr)
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        return try? JSONDecoder().decode(VersionInfo.self, from: data)
    }
    
    // MARK: - Private Helpers
    
    private func checkDisposed() throws {
        lock.lock()
        defer { lock.unlock() }
        
        if isDisposed {
            throw M3U8Error.disposed
        }
    }
}

// MARK: - Callback Manager

private final class CallbackManager: @unchecked Sendable {
    // 用于管理回调的辅助类
}
