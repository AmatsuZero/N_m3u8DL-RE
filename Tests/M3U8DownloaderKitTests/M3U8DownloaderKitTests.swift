//
//  M3U8DownloaderKitTests.swift
//  M3U8DownloaderKitTests
//
//  单元测试套件（纯 Swift 模型测试，不依赖 C 库）
//

import XCTest
@testable import M3U8DownloaderKitModels

final class M3U8DownloaderKitTests: XCTestCase {
    
    // MARK: - Test Streams (from TestStreams.md)
    
    struct TestURLs {
        // Apple HLS 示例
        static let appleBasic = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        static let appleAdvancedHEVC = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"
        static let appleFMP4VTT = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"
        
        // DASH 示例
        static let dashClear = "https://media.axprod.net/TestVectors/v7-Clear/Manifest_1080p.mpd"
        static let dashMultiRes = "https://dash.akamaized.net/dash264/TestCases/2c/qualcomm/1/MultiResMPEG2.mpd"
        
        // HLS VTT 示例
        static let hlsVTT = "https://storage.googleapis.com/shaka-demo-assets/angel-one-hls/hls.m3u8"
        
        // 加密流
        static let hlsAES = "http://playertest.longtailvideo.com/adaptive/oceans_aes/oceans_aes.m3u8"
        
        // 无效 URL
        static let invalid = "https://invalid.example.com/nonexistent.m3u8"
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationDefaults() {
        let config = Configuration.default
        
        XCTAssertEqual(config.maxConcurrency, 8)
        XCTAssertEqual(config.timeoutSeconds, 30)
        XCTAssertEqual(config.retryCount, 3)
        XCTAssertTrue(config.autoCleanup)
    }
    
    func testConfigurationCustomValues() {
        let config = Configuration(
            maxConcurrency: 16,
            timeoutSeconds: 120,
            retryCount: 10,
            tempDirectory: "/tmp/m3u8dl",
            autoCleanup: false,
            customHeaders: ["User-Agent": "TestAgent"]
        )
        
        XCTAssertEqual(config.maxConcurrency, 16)
        XCTAssertEqual(config.timeoutSeconds, 120)
        XCTAssertEqual(config.retryCount, 10)
        XCTAssertEqual(config.tempDirectory, "/tmp/m3u8dl")
        XCTAssertFalse(config.autoCleanup)
        XCTAssertEqual(config.customHeaders?["User-Agent"], "TestAgent")
    }
    
    func testConfigurationCodable() throws {
        let config = Configuration(
            maxConcurrency: 4,
            timeoutSeconds: 60,
            retryCount: 5,
            tempDirectory: "/tmp/test",
            autoCleanup: true,
            customHeaders: ["Authorization": "Bearer token"]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Configuration.self, from: data)
        
        XCTAssertEqual(decoded.maxConcurrency, config.maxConcurrency)
        XCTAssertEqual(decoded.timeoutSeconds, config.timeoutSeconds)
        XCTAssertEqual(decoded.retryCount, config.retryCount)
        XCTAssertEqual(decoded.tempDirectory, config.tempDirectory)
        XCTAssertEqual(decoded.autoCleanup, config.autoCleanup)
        XCTAssertEqual(decoded.customHeaders, config.customHeaders)
    }
    
    // MARK: - Download Options Tests
    
    func testDownloadOptionsDefaults() {
        let options = DownloadOptions.default
        
        XCTAssertNil(options.decryptionKeys)
        XCTAssertNil(options.customHeaders)
        XCTAssertTrue(options.autoSelectBestQuality)
    }
    
    func testDownloadOptionsCustomValues() {
        let options = DownloadOptions(
            decryptionKeys: ["key1", "key2"],
            customHeaders: ["Authorization": "Bearer token"],
            autoSelectBestQuality: false,
            selectedStreamIds: ["video-1", "audio-1"]
        )
        
        XCTAssertEqual(options.decryptionKeys?.count, 2)
        XCTAssertEqual(options.customHeaders?["Authorization"], "Bearer token")
        XCTAssertFalse(options.autoSelectBestQuality)
        XCTAssertEqual(options.selectedStreamIds?.count, 2)
    }
    
    // MARK: - Stream Type Tests
    
    func testStreamTypeDecoding() throws {
        let videoJSON = #"{"id":"v1","type":"video","codec":"avc1","bitrate":5000000,"resolution":"1920x1080","language":null,"isEncrypted":false}"#
        let audioJSON = #"{"id":"a1","type":"audio","codec":"mp4a","bitrate":128000,"resolution":null,"language":"en","isEncrypted":false}"#
        let subtitleJSON = #"{"id":"s1","type":"subtitle","codec":"vtt","bitrate":null,"resolution":null,"language":"en","isEncrypted":false}"#
        
        let decoder = JSONDecoder()
        
        let videoStream = try decoder.decode(StreamInfo.self, from: videoJSON.data(using: .utf8)!)
        XCTAssertEqual(videoStream.type, .video)
        XCTAssertEqual(videoStream.resolution, "1920x1080")
        XCTAssertEqual(videoStream.bitrate, 5000000)
        
        let audioStream = try decoder.decode(StreamInfo.self, from: audioJSON.data(using: .utf8)!)
        XCTAssertEqual(audioStream.type, .audio)
        XCTAssertEqual(audioStream.language, "en")
        XCTAssertEqual(audioStream.bitrate, 128000)
        
        let subtitleStream = try decoder.decode(StreamInfo.self, from: subtitleJSON.data(using: .utf8)!)
        XCTAssertEqual(subtitleStream.type, .subtitle)
        XCTAssertEqual(subtitleStream.codec, "vtt")
    }
    
    func testStreamTypeUnknown() throws {
        let unknownJSON = #"{"id":"u1","type":"something_else","codec":null,"bitrate":null,"resolution":null,"language":null,"isEncrypted":false}"#
        
        let decoder = JSONDecoder()
        let stream = try decoder.decode(StreamInfo.self, from: unknownJSON.data(using: .utf8)!)
        
        XCTAssertEqual(stream.type, .unknown)
    }
    
    // MARK: - Download Progress Tests
    
    func testDownloadProgressFormatting() {
        let progress = DownloadProgress(
            taskId: 1,
            description: "Downloading",
            currentValue: 50,
            maxValue: 100,
            percentage: 50.0,
            speed: 1048576,  // 1 MB/s
            downloadedBytes: 52428800,  // 50 MB
            totalBytes: 104857600  // 100 MB
        )
        
        XCTAssertEqual(progress.formattedProgress, "50.0%")
        XCTAssertTrue(progress.formattedSpeed.contains("MB"))
    }
    
    func testDownloadProgressZeroSpeed() {
        let progress = DownloadProgress(
            taskId: 1,
            description: "Starting",
            currentValue: 0,
            maxValue: 100,
            percentage: 0.0,
            speed: nil,
            downloadedBytes: 0,
            totalBytes: 104857600
        )
        
        XCTAssertEqual(progress.formattedSpeed, "N/A")
        XCTAssertEqual(progress.formattedProgress, "0.0%")
    }
    
    // MARK: - Download Result Tests
    
    func testDownloadResultFormatting() {
        let result = DownloadResult(
            success: true,
            outputFile: "/path/to/output.mp4",
            fileSize: 104857600,  // 100 MB
            duration: 3661.5,  // 1:01:01
            errorMessage: nil
        )
        
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.formattedFileSize.contains("MB"))
        XCTAssertEqual(result.formattedDuration, "1:01:01")
    }
    
    func testDurationFormattingShort() {
        let result = DownloadResult(
            success: true,
            outputFile: nil,
            fileSize: nil,
            duration: 125.0,  // 2:05
            errorMessage: nil
        )
        
        XCTAssertEqual(result.formattedDuration, "2:05")
    }
    
    func testDurationFormattingNil() {
        let result = DownloadResult(
            success: false,
            outputFile: nil,
            fileSize: nil,
            duration: nil,
            errorMessage: "Error"
        )
        
        XCTAssertEqual(result.formattedDuration, "N/A")
        XCTAssertEqual(result.formattedFileSize, "N/A")
    }
    
    // MARK: - Error Tests
    
    func testM3U8ErrorCodes() {
        XCTAssertEqual(M3U8Error.initializationFailed.code, 1001)
        XCTAssertEqual(M3U8Error.disposed.code, 1002)
        XCTAssertEqual(M3U8Error.invalidParameter(name: "test").code, 1003)
        XCTAssertEqual(M3U8Error.parseFailed(reason: "test").code, 2001)
        XCTAssertEqual(M3U8Error.downloadFailed(reason: "test").code, 2002)
        XCTAssertEqual(M3U8Error.cancelled.code, 2003)
    }
    
    func testM3U8ErrorDescriptions() {
        let error = M3U8Error.parseFailed(reason: "Invalid URL")
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.failureReason)
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.errorDescription!.contains("Invalid URL"))
    }
    
    func testAllErrorCases() {
        let errors: [M3U8Error] = [
            .initializationFailed,
            .disposed,
            .invalidParameter(name: "url"),
            .parseFailed(reason: "Invalid format"),
            .downloadFailed(reason: "Network timeout"),
            .cancelled,
            .unsupportedFeature(.hls),
            .invalidURL("http://invalid"),
            .networkError(underlying: NSError(domain: "test", code: 1)),
            .fileSystemError(underlying: NSError(domain: "test", code: 2)),
            .decryptionFailed(reason: "Invalid key"),
            .internalError(reason: "Unknown")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertNotNil(error.failureReason)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertGreaterThan(error.code, 0)
        }
    }
    
    // MARK: - Feature Tests
    
    func testFeatureRawValues() {
        XCTAssertEqual(Feature.decrypt.rawValue, "decrypt")
        XCTAssertEqual(Feature.merge.rawValue, "merge")
        XCTAssertEqual(Feature.mux.rawValue, "mux")
        XCTAssertEqual(Feature.hls.rawValue, "hls")
        XCTAssertEqual(Feature.dash.rawValue, "dash")
    }
    
    // MARK: - Log Level Tests
    
    func testLogLevelProperties() {
        XCTAssertEqual(LogLevel.debug.name, "DEBUG")
        XCTAssertEqual(LogLevel.info.name, "INFO")
        XCTAssertEqual(LogLevel.warning.name, "WARN")
        XCTAssertEqual(LogLevel.error.name, "ERROR")
        
        XCTAssertEqual(LogLevel.debug.symbol, "🔍")
        XCTAssertEqual(LogLevel.info.symbol, "ℹ️")
        XCTAssertEqual(LogLevel.warning.symbol, "⚠️")
        XCTAssertEqual(LogLevel.error.symbol, "❌")
    }
    
    func testLogLevelRawValues() {
        XCTAssertEqual(LogLevel.debug.rawValue, 0)
        XCTAssertEqual(LogLevel.info.rawValue, 1)
        XCTAssertEqual(LogLevel.warning.rawValue, 2)
        XCTAssertEqual(LogLevel.error.rawValue, 3)
    }
    
    // MARK: - Sendable Conformance Tests
    
    func testConfigurationIsSendable() {
        let config = Configuration.default
        
        Task {
            // 应该能在 Task 中使用
            let _ = config.maxConcurrency
        }
    }
    
    func testDownloadOptionsIsSendable() {
        let options = DownloadOptions.default
        
        Task {
            // 应该能在 Task 中使用
            let _ = options.autoSelectBestQuality
        }
    }
    
    // MARK: - Parse Result Tests
    
    func testParseResultSuccess() {
        let streams = [
            StreamInfo(id: "v1", type: .video, codec: "avc1", bitrate: 5000000, resolution: "1920x1080", language: nil, isEncrypted: false),
            StreamInfo(id: "a1", type: .audio, codec: "mp4a", bitrate: 128000, resolution: nil, language: "en", isEncrypted: false)
        ]
        
        let result = ParseResult(success: true, errorMessage: nil, streams: streams)
        
        XCTAssertTrue(result.success)
        XCTAssertNil(result.errorMessage)
        XCTAssertEqual(result.streams.count, 2)
    }
    
    func testParseResultFailure() {
        let result = ParseResult(success: false, errorMessage: "Invalid URL", streams: [])
        
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.errorMessage, "Invalid URL")
        XCTAssertTrue(result.streams.isEmpty)
    }
    
    // MARK: - Version Info Tests
    
    func testVersionInfoCodable() throws {
        let versionInfo = VersionInfo(
            version: "1.0.0",
            platform: "iOS",
            framework: "net8.0",
            buildDate: "2025-01-08"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(versionInfo)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(VersionInfo.self, from: data)
        
        XCTAssertEqual(decoded.version, "1.0.0")
        XCTAssertEqual(decoded.platform, "iOS")
        XCTAssertEqual(decoded.framework, "net8.0")
        XCTAssertEqual(decoded.buildDate, "2025-01-08")
    }
    
    // MARK: - Processor Tests
    
    func testProcessorCodable() throws {
        let processor = Processor(name: "FFmpeg", priority: 1)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(processor)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Processor.self, from: data)
        
        XCTAssertEqual(decoded.name, "FFmpeg")
        XCTAssertEqual(decoded.priority, 1)
    }
}

// MARK: - Performance Tests

final class M3U8DownloaderPerformanceTests: XCTestCase {
    
    func testConfigurationEncodingPerformance() throws {
        let config = Configuration(
            maxConcurrency: 8,
            timeoutSeconds: 30,
            retryCount: 3,
            customHeaders: ["User-Agent": "Test", "Accept": "*/*"]
        )
        
        let encoder = JSONEncoder()
        
        measure {
            for _ in 0..<1000 {
                _ = try? encoder.encode(config)
            }
        }
    }
    
    func testStreamInfoDecodingPerformance() throws {
        let json = #"{"id":"v1","type":"video","codec":"avc1","bitrate":5000000,"resolution":"1920x1080","language":null,"isEncrypted":false}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        measure {
            for _ in 0..<1000 {
                _ = try? decoder.decode(StreamInfo.self, from: data)
            }
        }
    }
    
    func testDownloadProgressFormattingPerformance() {
        let progress = DownloadProgress(
            taskId: 1,
            description: "Downloading",
            currentValue: 50,
            maxValue: 100,
            percentage: 50.0,
            speed: 1048576,
            downloadedBytes: 52428800,
            totalBytes: 104857600
        )
        
        measure {
            for _ in 0..<10000 {
                _ = progress.formattedSpeed
                _ = progress.formattedProgress
            }
        }
    }
}
