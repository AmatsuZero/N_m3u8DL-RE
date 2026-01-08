//
//  Models.swift
//  M3U8DownloaderKitModels
//
//  数据模型定义
//

import Foundation

// MARK: - Configuration

/// 下载器配置
public struct Configuration: Codable, Sendable {
    /// 最大并发数
    public var maxConcurrency: Int
    
    /// 超时时间（秒）
    public var timeoutSeconds: Int
    
    /// 重试次数
    public var retryCount: Int
    
    /// 临时目录
    public var tempDirectory: String?
    
    /// 自动清理
    public var autoCleanup: Bool
    
    /// 自定义请求头
    public var customHeaders: [String: String]?
    
    /// 默认配置
    public static let `default` = Configuration()
    
    public init(
        maxConcurrency: Int = 8,
        timeoutSeconds: Int = 30,
        retryCount: Int = 3,
        tempDirectory: String? = nil,
        autoCleanup: Bool = true,
        customHeaders: [String: String]? = nil
    ) {
        self.maxConcurrency = maxConcurrency
        self.timeoutSeconds = timeoutSeconds
        self.retryCount = retryCount
        self.tempDirectory = tempDirectory
        self.autoCleanup = autoCleanup
        self.customHeaders = customHeaders
    }
}

// MARK: - Download Options

/// 下载选项
public struct DownloadOptions: Sendable {
    /// 解密密钥列表
    public var decryptionKeys: [String]?
    
    /// 自定义请求头
    public var customHeaders: [String: String]?
    
    /// 自动选择最佳质量
    public var autoSelectBestQuality: Bool
    
    /// 选择的流 ID 列表
    public var selectedStreamIds: [String]?
    
    /// 默认选项
    public static let `default` = DownloadOptions()
    
    public init(
        decryptionKeys: [String]? = nil,
        customHeaders: [String: String]? = nil,
        autoSelectBestQuality: Bool = true,
        selectedStreamIds: [String]? = nil
    ) {
        self.decryptionKeys = decryptionKeys
        self.customHeaders = customHeaders
        self.autoSelectBestQuality = autoSelectBestQuality
        self.selectedStreamIds = selectedStreamIds
    }
}

// MARK: - Download Request (Internal)

public struct DownloadRequest: Codable, Sendable {
    public let url: String
    public let outputPath: String
    public let decryptionKeys: [String]?
    public let customHeaders: [String: String]?
    public let autoSelectBestQuality: Bool
    
    public init(url: String, outputPath: String, decryptionKeys: [String]?, customHeaders: [String: String]?, autoSelectBestQuality: Bool) {
        self.url = url
        self.outputPath = outputPath
        self.decryptionKeys = decryptionKeys
        self.customHeaders = customHeaders
        self.autoSelectBestQuality = autoSelectBestQuality
    }
}

// MARK: - Parse Result

/// 解析结果
public struct ParseResult: Codable, Sendable {
    /// 是否成功
    public let success: Bool
    
    /// 错误信息
    public let errorMessage: String?
    
    /// 可用流列表
    public let streams: [StreamInfo]
    
    public init(success: Bool = false, errorMessage: String? = nil, streams: [StreamInfo] = []) {
        self.success = success
        self.errorMessage = errorMessage
        self.streams = streams
    }
}

// MARK: - Stream Info

/// 流信息
public struct StreamInfo: Codable, Sendable, Identifiable {
    /// 流 ID
    public let id: String
    
    /// 流类型（video, audio, subtitle）
    public let type: StreamType
    
    /// 编解码器
    public let codec: String?
    
    /// 比特率（bps）
    public let bitrate: Int?
    
    /// 分辨率（如 "1920x1080"）
    public let resolution: String?
    
    /// 语言代码
    public let language: String?
    
    /// 是否加密
    public let isEncrypted: Bool
    
    /// 帧率
    public let frameRate: Double?
    
    /// 名称/标签
    public let name: String?
    
    public init(id: String, type: StreamType, codec: String?, bitrate: Int?, resolution: String?, language: String?, isEncrypted: Bool, frameRate: Double? = nil, name: String? = nil) {
        self.id = id
        self.type = type
        self.codec = codec
        self.bitrate = bitrate
        self.resolution = resolution
        self.language = language
        self.isEncrypted = isEncrypted
        self.frameRate = frameRate
        self.name = name
    }
}

/// 流类型
public enum StreamType: String, Codable, Sendable {
    case video
    case audio
    case subtitle
    case unknown
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        self = StreamType(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Download Progress

/// 下载进度
public struct DownloadProgress: Codable, Sendable {
    /// 任务 ID
    public let taskId: Int?
    
    /// 描述
    public let description: String?
    
    /// 当前值
    public let currentValue: Int?
    
    /// 最大值
    public let maxValue: Int?
    
    /// 进度百分比（0-100）
    public let percentage: Double
    
    /// 下载速度（字节/秒）
    public let speed: Int?
    
    /// 已下载字节数
    public let downloadedBytes: Int?
    
    /// 总字节数
    public let totalBytes: Int?
    
    public init(taskId: Int?, description: String?, currentValue: Int?, maxValue: Int?, percentage: Double, speed: Int?, downloadedBytes: Int?, totalBytes: Int?) {
        self.taskId = taskId
        self.description = description
        self.currentValue = currentValue
        self.maxValue = maxValue
        self.percentage = percentage
        self.speed = speed
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
    }
    
    /// 格式化的速度字符串
    public var formattedSpeed: String {
        guard let speed = speed else { return "N/A" }
        return ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .binary) + "/s"
    }
    
    /// 格式化的进度字符串
    public var formattedProgress: String {
        String(format: "%.1f%%", percentage)
    }
}

// MARK: - Download Result

/// 下载结果
public struct DownloadResult: Codable, Sendable {
    /// 是否成功
    public let success: Bool
    
    /// 输出文件路径
    public let outputFile: String?
    
    /// 文件大小（字节）
    public let fileSize: Int?
    
    /// 时长（秒）
    public let duration: Double?
    
    /// 错误信息
    public let errorMessage: String?
    
    public init(success: Bool, outputFile: String?, fileSize: Int?, duration: Double?, errorMessage: String?) {
        self.success = success
        self.outputFile = outputFile
        self.fileSize = fileSize
        self.duration = duration
        self.errorMessage = errorMessage
    }
    
    /// 格式化的文件大小
    public var formattedFileSize: String {
        guard let size = fileSize else { return "N/A" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .binary)
    }
    
    /// 格式化的时长
    public var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Processor

/// 视频处理器
public struct Processor: Codable, Sendable {
    /// 处理器名称
    public let name: String
    
    /// 优先级
    public let priority: Int
    
    public init(name: String, priority: Int) {
        self.name = name
        self.priority = priority
    }
}

// MARK: - Version Info

/// 版本信息
public struct VersionInfo: Codable, Sendable {
    /// 版本号
    public let version: String
    
    /// 平台
    public let platform: String
    
    /// 框架
    public let framework: String
    
    /// 构建日期
    public let buildDate: String?
    
    public init(version: String, platform: String, framework: String, buildDate: String?) {
        self.version = version
        self.platform = platform
        self.framework = framework
        self.buildDate = buildDate
    }
}

// MARK: - Feature

/// 功能枚举
public enum Feature: String, Sendable {
    /// 解密支持
    case decrypt
    
    /// 文件合并
    case merge
    
    /// 音视频混流
    case mux
    
    /// HLS 流支持
    case hls
    
    /// DASH 流支持
    case dash
}

// MARK: - Log Level

/// 日志级别
public enum LogLevel: Int, Sendable {
    /// 调试信息
    case debug = 0
    
    /// 一般信息
    case info = 1
    
    /// 警告
    case warning = 2
    
    /// 错误
    case error = 3
    
    /// 显示名称
    public var name: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }
    
    /// 符号
    public var symbol: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}
