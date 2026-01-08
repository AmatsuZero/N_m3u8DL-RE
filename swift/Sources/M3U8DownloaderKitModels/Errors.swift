//
//  Errors.swift
//  M3U8DownloaderKitModels
//
//  错误类型定义
//

import Foundation

// MARK: - M3U8Error

/// M3U8 下载器错误
public enum M3U8Error: LocalizedError, Sendable {
    /// 初始化失败
    case initializationFailed
    
    /// 实例已释放
    case disposed
    
    /// 无效参数
    case invalidParameter(name: String)
    
    /// 解析失败
    case parseFailed(reason: String)
    
    /// 下载失败
    case downloadFailed(reason: String)
    
    /// 操作被取消
    case cancelled
    
    /// 不支持的功能
    case unsupportedFeature(Feature)
    
    /// 无效的 URL
    case invalidURL(String)
    
    /// 网络错误
    case networkError(underlying: Error)
    
    /// 文件系统错误
    case fileSystemError(underlying: Error)
    
    /// 解密失败
    case decryptionFailed(reason: String)
    
    /// 内部错误
    case internalError(reason: String)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "下载器初始化失败"
        case .disposed:
            return "下载器实例已被释放"
        case .invalidParameter(let name):
            return "无效参数: \(name)"
        case .parseFailed(let reason):
            return "解析失败: \(reason)"
        case .downloadFailed(let reason):
            return "下载失败: \(reason)"
        case .cancelled:
            return "操作已取消"
        case .unsupportedFeature(let feature):
            return "不支持的功能: \(feature.rawValue)"
        case .invalidURL(let url):
            return "无效的 URL: \(url)"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .fileSystemError(let error):
            return "文件系统错误: \(error.localizedDescription)"
        case .decryptionFailed(let reason):
            return "解密失败: \(reason)"
        case .internalError(let reason):
            return "内部错误: \(reason)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .initializationFailed:
            return "无法创建下载器实例，可能是内存不足或配置错误"
        case .disposed:
            return "尝试在已释放的实例上执行操作"
        case .invalidParameter(let name):
            return "参数 '\(name)' 的值无效或缺失"
        case .parseFailed:
            return "无法解析流媒体源"
        case .downloadFailed:
            return "下载过程中发生错误"
        case .cancelled:
            return "用户或系统取消了操作"
        case .unsupportedFeature(let feature):
            return "当前配置不支持 \(feature.rawValue) 功能"
        case .invalidURL:
            return "URL 格式不正确或不可访问"
        case .networkError:
            return "网络连接问题"
        case .fileSystemError:
            return "文件读写权限问题"
        case .decryptionFailed:
            return "密钥不正确或加密格式不支持"
        case .internalError:
            return "库内部发生意外错误"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .initializationFailed:
            return "请检查配置参数是否正确，并确保有足够的系统资源"
        case .disposed:
            return "请创建新的下载器实例"
        case .invalidParameter:
            return "请检查传入的参数值"
        case .parseFailed:
            return "请检查 URL 是否正确，以及网络连接是否正常"
        case .downloadFailed:
            return "请检查网络连接，或尝试重新下载"
        case .cancelled:
            return "如需继续，请重新开始下载"
        case .unsupportedFeature:
            return "请检查是否安装了必要的组件"
        case .invalidURL:
            return "请检查 URL 格式是否正确"
        case .networkError:
            return "请检查网络连接并重试"
        case .fileSystemError:
            return "请检查文件权限和磁盘空间"
        case .decryptionFailed:
            return "请确认解密密钥是否正确"
        case .internalError:
            return "请尝试重启应用或联系技术支持"
        }
    }
}

// MARK: - Error Code

extension M3U8Error {
    /// 错误代码
    public var code: Int {
        switch self {
        case .initializationFailed: return 1001
        case .disposed: return 1002
        case .invalidParameter: return 1003
        case .parseFailed: return 2001
        case .downloadFailed: return 2002
        case .cancelled: return 2003
        case .unsupportedFeature: return 3001
        case .invalidURL: return 4001
        case .networkError: return 4002
        case .fileSystemError: return 4003
        case .decryptionFailed: return 5001
        case .internalError: return 9999
        }
    }
}
