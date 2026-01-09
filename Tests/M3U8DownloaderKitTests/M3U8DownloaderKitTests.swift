//
//  M3U8DownloaderKitTests.swift
//  M3U8DownloaderKitTests
//
//  单元测试套件
//  注意：由于依赖 M3U8Core.xcframework，完整测试需要在真实设备或模拟器上运行
//

import XCTest

// 导入 ObjC 模块 - 需要在 Xcode 项目或 CocoaPods 环境中运行
#if canImport(M3U8DownloaderKitObjC)
import M3U8DownloaderKitObjC
#endif

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
    
    // MARK: - Basic Tests
    
    /// 测试 URL 字符串有效性
    func testURLStringsAreValid() {
        let urls = [
            TestURLs.appleBasic,
            TestURLs.appleAdvancedHEVC,
            TestURLs.dashClear,
            TestURLs.hlsVTT
        ]
        
        for urlString in urls {
            XCTAssertNotNil(URL(string: urlString), "URL should be valid: \(urlString)")
        }
    }
    
    /// 测试无效 URL
    func testInvalidURLString() {
        let url = URL(string: TestURLs.invalid)
        XCTAssertNotNil(url, "Invalid URL should still be parseable as URL object")
    }
}

// MARK: - ObjC API Tests

#if canImport(M3U8DownloaderKitObjC)

/// M3U8Downloader Objective-C API 测试
/// 注意：这些测试需要 M3U8Core.xcframework 正确链接才能运行
final class M3U8DownloaderObjCTests: XCTestCase {
    
    var downloader: M3U8Downloader!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        downloader = M3U8Downloader()
    }
    
    override func tearDownWithError() throws {
        downloader?.dispose()
        downloader = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testDownloaderInitialization() {
        XCTAssertNotNil(downloader, "Downloader should be initialized")
        XCTAssertFalse(downloader.isDisposed, "Downloader should not be disposed after init")
    }
    
    func testDownloaderWithConfiguration() {
        let config = M3U8Configuration()
        config.maxConcurrency = 16
        config.timeoutSeconds = 60
        config.retryCount = 5
        
        let configuredDownloader = M3U8Downloader(configuration: config)
        XCTAssertNotNil(configuredDownloader, "Downloader with config should be initialized")
        
        configuredDownloader?.dispose()
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() {
        let config = M3U8Configuration.default()
        
        XCTAssertEqual(config.maxConcurrency, 8)
        XCTAssertEqual(config.timeoutSeconds, 30)
        XCTAssertEqual(config.retryCount, 3)
        XCTAssertTrue(config.autoCleanup)
    }
    
    func testCustomConfiguration() {
        let config = M3U8Configuration()
        config.maxConcurrency = 4
        config.timeoutSeconds = 120
        config.retryCount = 10
        config.autoCleanup = false
        config.tempDirectory = "/tmp/m3u8dl_test"
        config.customHeaders = ["User-Agent": "TestAgent/1.0"]
        
        XCTAssertEqual(config.maxConcurrency, 4)
        XCTAssertEqual(config.timeoutSeconds, 120)
        XCTAssertEqual(config.retryCount, 10)
        XCTAssertFalse(config.autoCleanup)
        XCTAssertEqual(config.tempDirectory, "/tmp/m3u8dl_test")
        XCTAssertEqual(config.customHeaders?["User-Agent"], "TestAgent/1.0")
    }
    
    // MARK: - Download Options Tests
    
    func testDefaultDownloadOptions() {
        let options = M3U8DownloadOptions.default()
        
        XCTAssertNil(options.decryptionKeys)
        XCTAssertNil(options.customHeaders)
        XCTAssertTrue(options.autoSelectBestQuality)
    }
    
    func testCustomDownloadOptions() {
        let options = M3U8DownloadOptions()
        options.decryptionKeys = ["key1", "key2"]
        options.customHeaders = ["Authorization": "Bearer token"]
        options.autoSelectBestQuality = false
        options.selectedStreamIds = ["video-1", "audio-1"]
        
        XCTAssertEqual(options.decryptionKeys?.count, 2)
        XCTAssertEqual(options.customHeaders?["Authorization"], "Bearer token")
        XCTAssertFalse(options.autoSelectBestQuality)
        XCTAssertEqual(options.selectedStreamIds?.count, 2)
    }
    
    // MARK: - Dispose Tests
    
    func testDisposeDownloader() {
        let tempDownloader = M3U8Downloader()
        XCTAssertNotNil(tempDownloader)
        XCTAssertFalse(tempDownloader!.isDisposed)
        
        tempDownloader?.dispose()
        XCTAssertTrue(tempDownloader!.isDisposed)
    }
    
    // MARK: - Error Domain Tests
    
    func testErrorDomain() {
        XCTAssertEqual(M3U8ErrorDomain, "com.m3u8dl.M3U8DownloaderKit")
    }
    
    func testErrorCodes() {
        XCTAssertEqual(M3U8ErrorCodeInitializationFailed, 1001)
        XCTAssertEqual(M3U8ErrorCodeDisposed, 1002)
        XCTAssertEqual(M3U8ErrorCodeInvalidParameter, 1003)
        XCTAssertEqual(M3U8ErrorCodeParseFailed, 2001)
        XCTAssertEqual(M3U8ErrorCodeDownloadFailed, 2002)
        XCTAssertEqual(M3U8ErrorCodeCancelled, 2003)
    }
    
    // MARK: - Parse Tests (需要网络)
    
    func testParseValidURL() {
        let expectation = expectation(description: "Parse completion")
        
        downloader.parse(M3U8DownloaderKitTests.TestURLs.appleBasic) { result, error in
            if let error = error {
                // 网络错误是可接受的，因为可能没有网络
                print("Parse error (may be expected): \(error)")
            } else if let result = result {
                XCTAssertTrue(result.success)
                XCTAssertGreaterThan(result.streams.count, 0)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30)
    }
    
    func testParseInvalidURL() {
        let expectation = expectation(description: "Parse completion")
        
        downloader.parse(M3U8DownloaderKitTests.TestURLs.invalid) { result, error in
            // 应该失败
            if let result = result {
                XCTAssertFalse(result.success)
            } else {
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30)
    }
}

#endif

// MARK: - Performance Tests

final class M3U8DownloaderPerformanceTests: XCTestCase {
    
    func testURLParsingPerformance() {
        let urlString = M3U8DownloaderKitTests.TestURLs.appleBasic
        
        measure {
            for _ in 0..<10000 {
                _ = URL(string: urlString)
            }
        }
    }
}
