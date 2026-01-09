//
//  M3U8VideoMergeTests.m
//  M3U8DownloaderKitTests
//
//  视频合并功能测试
//

#import <XCTest/XCTest.h>
#import "M3U8VideoMerge.h"

@interface M3U8VideoMergeTests : XCTestCase
@property (nonatomic, strong) M3U8AVFoundationProcessor *processor;
@property (nonatomic, strong) NSString *testDataPath;
@end

@implementation M3U8VideoMergeTests

- (void)setUp {
    [super setUp];
    
    // 创建处理器
    self.processor = [M3U8AVFoundationProcessor processor];
    
    // 注册处理器
    [[M3U8VideoProcessorRegistry sharedRegistry] registerProcessor:self.processor];
    
    // 设置测试数据路径
    self.testDataPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"M3U8VideoMergeTests"];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.testDataPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
}

- (void)tearDown {
    // 清理测试数据
    [[NSFileManager defaultManager] removeItemAtPath:self.testDataPath error:nil];
    
    // 清空注册表
    [[M3U8VideoProcessorRegistry sharedRegistry] clearAllProcessors];
    
    [super tearDown];
}

#pragma mark - 基础测试

- (void)testProcessorAvailability {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Check processor availability"];
    
    [self.processor isAvailableWithCompletion:^(BOOL available) {
        XCTAssertTrue(available, @"AVFoundation处理器应该可用");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testProcessorProperties {
    XCTAssertEqualObjects(self.processor.name, @"AVFoundation");
    XCTAssertEqual(self.processor.priority, 100);
}

- (void)testFeatureSupport {
    XCTAssertTrue([self.processor supportsFeature:M3U8VideoProcessorFeatureHardwareAcceleration]);
    XCTAssertTrue([self.processor supportsFeature:M3U8VideoProcessorFeatureAudioMixing]);
    XCTAssertTrue([self.processor supportsFeature:M3U8VideoProcessorFeatureVideoComposition]);
    XCTAssertTrue([self.processor supportsFeature:M3U8VideoProcessorFeatureResolutionScaling]);
    XCTAssertTrue([self.processor supportsFeature:M3U8VideoProcessorFeatureBatchProcessing]);
    XCTAssertTrue([self.processor supportsFeature:M3U8VideoProcessorFeatureCancellation]);
}

#pragma mark - 数据模型测试

- (void)testMergeOptionsDefaultValues {
    M3U8MergeOptions *options = [M3U8MergeOptions defaultOptions];
    
    XCTAssertEqual(options.outputFormat, M3U8OutputFormatMP4);
    XCTAssertTrue(options.useAACFilter);
    XCTAssertTrue(options.writeMetadata);
    XCTAssertEqual(options.scalingStrategy, M3U8ScalingStrategyScaleToFirst);
    XCTAssertTrue(options.optimizeForNetworkUse);
    XCTAssertEqual(options.maxRetryCount, 3);
    XCTAssertEqual(options.retryDelay, 1.0);
}

- (void)testMergeRequestValidation {
    // 测试空输入文件
    M3U8MergeRequest *request = [M3U8MergeRequest requestWithInputFiles:@[]
                                                               outputURL:[NSURL fileURLWithPath:@"/tmp/output.mp4"]
                                                                 options:nil];
    
    NSError *error = nil;
    BOOL valid = [request validateWithError:&error];
    
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, 1001);
}

- (void)testCancellationToken {
    M3U8CancellationToken *token = [[M3U8CancellationToken alloc] init];
    
    XCTAssertFalse(token.isCancelled);
    
    __block BOOL handlerCalled = NO;
    [token registerCancellationHandler:^{
        handlerCalled = YES;
    }];
    
    [token cancel];
    
    XCTAssertTrue(token.isCancelled);
    
    // 等待回调执行
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    XCTAssertTrue(handlerCalled);
}

#pragma mark - 注册表测试

- (void)testProcessorRegistry {
    M3U8VideoProcessorRegistry *registry = [M3U8VideoProcessorRegistry sharedRegistry];
    
    // 测试单例
    XCTAssertEqual(registry, [M3U8VideoProcessorRegistry sharedRegistry]);
    
    // 测试注册
    M3U8AVFoundationProcessor *processor = [M3U8AVFoundationProcessor processor];
    [registry registerProcessor:processor];
    
    // 测试查询
    id<M3U8VideoProcessor> found = [registry getProcessorByName:@"AVFoundation"];
    XCTAssertNotNil(found);
    XCTAssertEqualObjects(found.name, @"AVFoundation");
    
    // 测试获取所有处理器名称
    NSArray<NSString *> *names = [registry getAllProcessorNames];
    XCTAssertTrue([names containsObject:@"AVFoundation"]);
}

- (void)testGetBestProcessor {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Get best processor"];
    
    [[M3U8VideoProcessorRegistry sharedRegistry] getBestProcessorWithCompletion:^(id<M3U8VideoProcessor> processor) {
        XCTAssertNotNil(processor);
        XCTAssertEqualObjects(processor.name, @"AVFoundation");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testGetProcessorsByFeature {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Get processors by feature"];
    
    [[M3U8VideoProcessorRegistry sharedRegistry] getProcessorsByFeature:M3U8VideoProcessorFeatureHardwareAcceleration
                                                              completion:^(NSArray<id<M3U8VideoProcessor>> *processors) {
        XCTAssertGreaterThan(processors.count, 0);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - 性能测试

- (void)testPerformanceStatistics {
    M3U8MergeStatistics *stats = [[M3U8MergeStatistics alloc] init];
    stats.processorName = @"AVFoundation";
    stats.inputFileCount = 100;
    stats.totalInputSize = 1024 * 1024 * 100; // 100MB
    stats.outputSize = 1024 * 1024 * 95; // 95MB
    stats.totalDuration = 10.0;
    stats.averageSpeed = 10.0; // 10MB/s
    stats.peakMemoryUsage = 1024 * 1024 * 50; // 50MB
    stats.batchCount = 1;
    stats.hardwareAccelerated = YES;
    
    NSString *description = [stats formattedDescription];
    XCTAssertNotNil(description);
    XCTAssertTrue([description containsString:@"AVFoundation"]);
    XCTAssertTrue([description containsString:@"100"]);
}

#pragma mark - 集成测试（需要真实视频文件）

/*
 注意：以下测试需要真实的视频文件才能运行。
 在实际测试环境中，应该准备测试视频文件。
 */

- (void)testBasicMerge {
    // 这个测试需要真实的视频文件
    // 在CI/CD环境中应该准备测试资源
    
    // 示例代码（需要真实文件）:
    /*
    NSArray<NSURL *> *inputFiles = @[
        [NSURL fileURLWithPath:[self.testDataPath stringByAppendingPathComponent:@"video1.ts"]],
        [NSURL fileURLWithPath:[self.testDataPath stringByAppendingPathComponent:@"video2.ts"]]
    ];
    
    NSURL *outputURL = [NSURL fileURLWithPath:[self.testDataPath stringByAppendingPathComponent:@"output.mp4"]];
    
    M3U8MergeRequest *request = [M3U8MergeRequest requestWithInputFiles:inputFiles
                                                               outputURL:outputURL
                                                                 options:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Merge completion"];
    
    [self.processor mergeWithRequest:request completion:^(M3U8MergeResult *result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);
        XCTAssertTrue(result.success);
        XCTAssertNotNil(result.outputURL);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    */
}

@end
