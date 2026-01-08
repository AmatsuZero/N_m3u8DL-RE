//
//  MockImplementation.swift
//  M3U8DownloaderKit
//
//  Mock implementations for testing without the actual C library
//

import Foundation

#if DEBUG && TESTING

// MARK: - Mock C Function Implementations

/// 模拟初始化函数
@_cdecl("m3u8dl_init")
public func mock_m3u8dl_init(_ config: UnsafePointer<CChar>?) -> Int32 {
    return 1 // 返回有效句柄
}

/// 模拟释放函数
@_cdecl("m3u8dl_dispose")
public func mock_m3u8dl_dispose(_ handle: Int32) {
    // 空实现
}

/// 模拟解析函数
@_cdecl("m3u8dl_parse")
public func mock_m3u8dl_parse(_ handle: Int32, _ url: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    let mockResult = """
    {
        "success": true,
        "streams": [
            {"id": "v1", "type": "video", "codec": "avc1", "bitrate": 5000000, "resolution": "1920x1080", "language": null, "isEncrypted": false},
            {"id": "a1", "type": "audio", "codec": "mp4a", "bitrate": 128000, "resolution": null, "language": "en", "isEncrypted": false}
        ],
        "duration": 3600,
        "isLive": false,
        "title": "Mock Stream"
    }
    """
    let cString = strdup(mockResult)
    return cString
}

/// 模拟下载函数
@_cdecl("m3u8dl_download")
public func mock_m3u8dl_download(_ handle: Int32, _ url: UnsafePointer<CChar>?, _ output: UnsafePointer<CChar>?, _ options: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    let mockResult = """
    {
        "success": true,
        "outputFile": "/tmp/mock_output.mp4",
        "fileSize": 104857600,
        "duration": 3600.0,
        "errorMessage": null
    }
    """
    let cString = strdup(mockResult)
    return cString
}

/// 模拟异步下载函数
@_cdecl("m3u8dl_download_async")
public func mock_m3u8dl_download_async(_ handle: Int32, _ url: UnsafePointer<CChar>?, _ output: UnsafePointer<CChar>?, _ options: UnsafePointer<CChar>?) -> Int32 {
    return 1 // 返回任务 ID
}

/// 模拟取消函数
@_cdecl("m3u8dl_cancel")
public func mock_m3u8dl_cancel(_ handle: Int32) {
    // 空实现
}

/// 模拟获取处理器函数
@_cdecl("m3u8dl_get_processors")
public func mock_m3u8dl_get_processors() -> UnsafeMutablePointer<CChar>? {
    let mockResult = """
    [
        {"name": "FFmpeg", "version": "6.0", "available": true},
        {"name": "MP4Box", "version": "2.2", "available": true}
    ]
    """
    let cString = strdup(mockResult)
    return cString
}

/// 模拟获取版本函数
@_cdecl("m3u8dl_get_version")
public func mock_m3u8dl_get_version() -> UnsafeMutablePointer<CChar>? {
    let mockResult = """
    {
        "version": "1.0.0-mock",
        "platform": "macOS-test",
        "buildDate": "2025-01-08",
        "features": ["hls", "dash", "decrypt", "merge"]
    }
    """
    let cString = strdup(mockResult)
    return cString
}

/// 模拟功能支持检查函数
@_cdecl("m3u8dl_is_feature_supported")
public func mock_m3u8dl_is_feature_supported(_ feature: UnsafePointer<CChar>?) -> Bool {
    return true
}

/// 模拟释放字符串函数
@_cdecl("m3u8dl_free_string")
public func mock_m3u8dl_free_string(_ ptr: UnsafeMutablePointer<CChar>?) {
    if let ptr = ptr {
        free(ptr)
    }
}

/// 模拟设置日志回调函数
@_cdecl("m3u8dl_set_log_callback")
public func mock_m3u8dl_set_log_callback(_ callback: (@convention(c) (Int32, UnsafePointer<CChar>?) -> Void)?) {
    // 空实现
}

/// 模拟设置进度回调函数
@_cdecl("m3u8dl_set_progress_callback")
public func mock_m3u8dl_set_progress_callback(_ callback: (@convention(c) (Int32, UnsafePointer<CChar>?) -> Void)?) {
    // 空实现
}

/// 模拟设置完成回调函数
@_cdecl("m3u8dl_set_completion_callback")
public func mock_m3u8dl_set_completion_callback(_ callback: (@convention(c) (Int32, UnsafePointer<CChar>?) -> Void)?) {
    // 空实现
}

#endif
