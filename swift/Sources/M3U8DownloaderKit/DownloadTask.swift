//
//  DownloadTask.swift
//  M3U8DownloaderKit
//
//  下载任务封装
//

import Foundation
import M3U8DownloaderKit_C

// MARK: - DownloadTask

/// 下载任务
///
/// 表示一个正在进行的下载任务，支持进度监控和取消操作。
///
/// ## 示例
///
/// ```swift
/// let task = try downloader.downloadAsync(
///     url: "https://example.com/playlist.m3u8",
///     to: outputPath
/// )
///
/// // 监听进度
/// for await progress in task.progressStream {
///     print("进度: \(progress.percentage)%")
/// }
///
/// // 取消任务
/// task.cancel()
/// ```
public final class DownloadTask: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// 关联的下载器
    private weak var downloader: M3U8Downloader?
    
    /// 实例 ID
    private let instanceId: m3u8dl_instance_t
    
    /// 任务状态
    public private(set) var state: State = .running
    
    /// 完成回调
    private var completionContinuation: CheckedContinuation<DownloadResult, Error>?
    
    // MARK: - Types
    
    /// 任务状态
    public enum State: Sendable {
        /// 运行中
        case running
        
        /// 已暂停
        case paused
        
        /// 已取消
        case cancelled
        
        /// 已完成
        case completed
        
        /// 失败
        case failed
    }
    
    // MARK: - Initialization
    
    init(downloader: M3U8Downloader, instanceId: m3u8dl_instance_t) {
        self.downloader = downloader
        self.instanceId = instanceId
    }
    
    // MARK: - Public API
    
    /// 取消下载任务
    public func cancel() {
        guard state == .running else { return }
        state = .cancelled
        downloader?.cancel()
    }
    
    /// 等待任务完成
    ///
    /// - Returns: 下载结果
    /// - Throws: 如果下载失败或被取消
    public func wait() async throws -> DownloadResult {
        try await withCheckedThrowingContinuation { continuation in
            self.completionContinuation = continuation
        }
    }
    
    /// 进度流
    public var progressStream: AsyncStream<DownloadProgress> {
        downloader?.progressStream ?? AsyncStream { $0.finish() }
    }
    
    // MARK: - Internal
    
    func handleCompletion(result: DownloadResult) {
        if result.success {
            state = .completed
        } else {
            state = .failed
        }
        
        if result.success {
            completionContinuation?.resume(returning: result)
        } else {
            completionContinuation?.resume(throwing: M3U8Error.downloadFailed(reason: result.errorMessage ?? "Unknown error"))
        }
        completionContinuation = nil
    }
}

// MARK: - Download Builder

/// 下载构建器
///
/// 提供链式 API 来配置和启动下载任务。
///
/// ## 示例
///
/// ```swift
/// let result = try await M3U8Downloader.download("https://example.com/playlist.m3u8")
///     .to("/path/to/output.mp4")
///     .withHeaders(["User-Agent": "MyApp/1.0"])
///     .autoSelectBestQuality()
///     .start()
/// ```
public final class DownloadBuilder: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let url: String
    private var outputPath: String?
    private var configuration: Configuration?
    private var options = DownloadOptions()
    
    // MARK: - Initialization
    
    init(url: String) {
        self.url = url
    }
    
    // MARK: - Builder Methods
    
    /// 设置输出路径
    ///
    /// - Parameter path: 输出文件路径
    /// - Returns: 构建器实例
    public func to(_ path: String) -> Self {
        self.outputPath = path
        return self
    }
    
    /// 设置配置
    ///
    /// - Parameter configuration: 下载器配置
    /// - Returns: 构建器实例
    public func withConfiguration(_ configuration: Configuration) -> Self {
        self.configuration = configuration
        return self
    }
    
    /// 设置自定义请求头
    ///
    /// - Parameter headers: 请求头字典
    /// - Returns: 构建器实例
    public func withHeaders(_ headers: [String: String]) -> Self {
        self.options.customHeaders = headers
        return self
    }
    
    /// 设置解密密钥
    ///
    /// - Parameter keys: 解密密钥列表
    /// - Returns: 构建器实例
    public func withDecryptionKeys(_ keys: [String]) -> Self {
        self.options.decryptionKeys = keys
        return self
    }
    
    /// 启用自动选择最佳质量
    ///
    /// - Returns: 构建器实例
    public func autoSelectBestQuality() -> Self {
        self.options.autoSelectBestQuality = true
        return self
    }
    
    /// 选择特定流
    ///
    /// - Parameter streamIds: 流 ID 列表
    /// - Returns: 构建器实例
    public func selectStreams(_ streamIds: [String]) -> Self {
        self.options.selectedStreamIds = streamIds
        self.options.autoSelectBestQuality = false
        return self
    }
    
    /// 开始下载
    ///
    /// - Returns: 下载结果
    /// - Throws: 如果下载失败
    public func start() async throws -> DownloadResult {
        guard let outputPath = outputPath else {
            throw M3U8Error.invalidParameter(name: "outputPath")
        }
        
        let downloader = try M3U8Downloader(configuration: configuration)
        return try await downloader.download(url: url, to: outputPath, options: options)
    }
    
    /// 开始异步下载
    ///
    /// - Returns: 下载任务
    /// - Throws: 如果无法启动下载
    public func startAsync() throws -> DownloadTask {
        guard let outputPath = outputPath else {
            throw M3U8Error.invalidParameter(name: "outputPath")
        }
        
        let downloader = try M3U8Downloader(configuration: configuration)
        return try downloader.downloadAsync(url: url, to: outputPath, options: options)
    }
}

// MARK: - M3U8Downloader Extension

extension M3U8Downloader {
    /// 快速下载（静态方法）
    ///
    /// - Parameter url: 流媒体 URL
    /// - Returns: 下载构建器
    ///
    /// ## 示例
    ///
    /// ```swift
    /// let result = try await M3U8Downloader.download("https://example.com/playlist.m3u8")
    ///     .to("/path/to/output.mp4")
    ///     .start()
    /// ```
    public static func download(_ url: String) -> DownloadBuilder {
        DownloadBuilder(url: url)
    }
}
