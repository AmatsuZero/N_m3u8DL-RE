//
//  M3U8VideoMergeTests.swift
//  M3U8DownloaderKitTests
//
//  视频合并功能测试（Swift 版本）
//

import XCTest
@testable import M3U8DownloaderKit
@testable import M3U8VideoMerge

final class M3U8VideoMergeTests: XCTestCase {
    var processor: M3U8AVFoundationProcessor!
    var testDataPath: String!
    
    override func setUp() {
        super.setUp()

        // 创建处理器
        processor = M3U8AVFoundationProcessor()

        // 注册处理器
        M3U8VideoProcessorRegistry.shared().register(processor)

        // 设置测试数据路径
        let tempDir = NSTemporaryDirectory()
        testDataPath = URL(fileURLWithPath: tempDir).appendingPathComponent("M3U8VideoMergeTests").path
        try? FileManager.default.createDirectory(atPath: testDataPath,
                                                  withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        // 清理测试数据
        try? FileManager.default.removeItem(atPath: testDataPath)
        
        // 清空注册表
        M3U8VideoProcessorRegistry.shared().clearAllProcessors()
        
        super.tearDown()
    }
    
    // MARK: - 基础测试
    
    func testProcessorAvailability() async {
        // 测试处理器是否可用（异步检查）
        let available = await processor.isAvailable()
        XCTAssertTrue(available, "AVFoundation处理器应该可用")
    }
    
    func testProcessorProperties() {
        XCTAssertEqual(processor.name, "AVFoundation")
        XCTAssertEqual(processor.priority, 100)
    }
    
    func testFeatureSupport() {
        XCTAssertTrue(processor.supportsFeature(M3U8VideoProcessorFeatureHardwareAcceleration))
        XCTAssertTrue(processor.supportsFeature(M3U8VideoProcessorFeatureAudioMixing))
        XCTAssertTrue(processor.supportsFeature(M3U8VideoProcessorFeatureVideoComposition))
        XCTAssertTrue(processor.supportsFeature(M3U8VideoProcessorFeatureResolutionScaling))
        XCTAssertTrue(processor.supportsFeature(M3U8VideoProcessorFeatureBatchProcessing))
        XCTAssertTrue(processor.supportsFeature(M3U8VideoProcessorFeatureCancellation))
    }
    
    // MARK: - 数据模型测试
    
    func testMergeOptionsDefaultValues() {
        let options = M3U8MergeOptions.default()

        XCTAssertEqual(options.outputFormat, .MP4)
        XCTAssertTrue(options.useAACFilter)
        XCTAssertTrue(options.writeMetadata)
        XCTAssertEqual(options.scalingStrategy, .scaleToFirst)
        XCTAssertTrue(options.optimizeForNetworkUse)
        XCTAssertEqual(options.maxRetryCount, 3)
        XCTAssertEqual(options.retryDelay, 1.0)
    }
    
    func testMergeRequestValidation() {
        // 测试空输入文件
        let request = M3U8MergeRequest()
        request.inputFiles = []
        request.outputURL = URL(fileURLWithPath: "/tmp/output.mp4")
        request.options = nil

        do {
            try request.validate()
            XCTFail("应该抛出异常")
        } catch {
            // 预期会抛出异常
            XCTAssertNotNil(error)
        }
    }
    
    func testCancellationToken() {
        let token = M3U8CancellationToken()
        
        XCTAssertFalse(token.isCancelled)
        
        var handlerCalled = false
        token.registerCancellationHandler {
            handlerCalled = true
        }
        
        token.cancel()
        
        XCTAssertTrue(token.isCancelled)
        
        // 等待回调执行
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        
        XCTAssertTrue(handlerCalled)
    }
    
    // MARK: - 注册表测试
    
    func testProcessorRegistry() {
        let registry = M3U8VideoProcessorRegistry.shared()

        // 测试单例
        XCTAssertEqual(registry, M3U8VideoProcessorRegistry.shared())

        // 测试注册
        let processor = M3U8AVFoundationProcessor()
        registry.register(processor)

        // 测试查询
        let found = registry.getProcessorByName("AVFoundation")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "AVFoundation")

        // 测试获取所有处理器名称
        let names = registry.getAllProcessorNames()
        XCTAssertTrue(names.contains("AVFoundation"))
    }
    
    func testGetBestProcessor() {
        let expectation = XCTestExpectation(description: "Get best processor")

        M3U8VideoProcessorRegistry.shared().getBestProcessor { processor in
            XCTAssertNotNil(processor)
            XCTAssertEqual(processor?.name, "AVFoundation")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetProcessorsByFeature() {
        let expectation = XCTestExpectation(description: "Get processors by feature")

        M3U8VideoProcessorRegistry.shared().getProcessorsByFeature(M3U8VideoProcessorFeatureHardwareAcceleration) { processors in
            XCTAssertGreaterThan(processors.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - 性能测试
    
    func testPerformanceStatistics() {
        let stats = M3U8MergeStatistics()
        stats.processorName = "AVFoundation"
        stats.inputFileCount = 100
        stats.totalInputSize = 1024 * 1024 * 100 // 100MB
        stats.outputSize = 1024 * 1024 * 95 // 95MB
        stats.totalDuration = 10.0
        stats.averageSpeed = 10.0 // 10MB/s
        stats.peakMemoryUsage = 1024 * 1024 * 50 // 50MB
        stats.batchCount = 1
        stats.hardwareAccelerated = true
        
        let description = stats.formattedDescription()
        XCTAssertNotNil(description)
        XCTAssertTrue(description.contains("AVFoundation"))
        XCTAssertTrue(description.contains("100"))
    }
    
    // MARK: - 集成测试（需要真实视频文件）
    
    /*
     注意：以下测试需要真实的视频文件才能运行。
     在实际测试环境中，应该准备测试视频文件。
     */
    
    func testBasicMerge() {
        // 这个测试需要真实的视频文件
        // 在CI/CD环境中应该准备测试资源
        
        // 示例代码（需要真实文件）:
        /*
        let inputFiles = [
            URL(fileURLWithPath: testDataPath.appendingPathComponent("video1.ts")),
            URL(fileURLWithPath: testDataPath.appendingPathComponent("video2.ts"))
        ]
        
        let outputURL = URL(fileURLWithPath: testDataPath.appendingPathComponent("output.mp4"))
        
        let request = M3U8MergeRequest(inputFiles: inputFiles,
                                        outputURL: outputURL,
                                        options: nil)
        
        let expectation = XCTestExpectation(description: "Merge completion")
        
        processor.merge(with: request) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertTrue(result?.success ?? false)
            XCTAssertNotNil(result?.outputURL)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
        */
    }
}
