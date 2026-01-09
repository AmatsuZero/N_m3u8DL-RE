//
//  M3U8AVFoundationProcessor.m
//  M3U8DownloaderKit
//
//  基于AVFoundation的视频处理器实现
//

#import "M3U8AVFoundationProcessor.h"
#import "M3U8MergeRequest.h"
#import "M3U8MergeResult.h"
#import "M3U8MergeOptions.h"
#import "M3U8MergeStatistics.h"
#import "M3U8CancellationToken.h"
#import <AVFoundation/AVFoundation.h>
#import <TargetConditionals.h>
#import <mach/mach.h>

@interface M3U8AVFoundationProcessor ()
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, strong) NSMutableArray<NSURL *> *temporaryFiles;

// 分辨率检测和处理
- (CGSize)detectResolutionInconsistency:(NSArray<NSURL *> *)inputFiles;
- (AVVideoComposition *)createVideoCompositionForSize:(CGSize)targetSize
                                          composition:(AVMutableComposition *)composition
                                       scalingStrategy:(M3U8ScalingStrategy)strategy;
@end

@implementation M3U8AVFoundationProcessor

+ (instancetype)processor {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _processingQueue = dispatch_queue_create("com.m3u8downloader.avfoundation", DISPATCH_QUEUE_SERIAL);
        _temporaryFiles = [NSMutableArray array];
    }
    return self;
}

#pragma mark - M3U8VideoProcessor Protocol

- (NSString *)name {
    return @"AVFoundation";
}

- (NSInteger)priority {
    return 100;
}

- (void)isAvailableWithCompletion:(void (^)(BOOL))completion {
    if (!completion) {
        return;
    }
    
    // 检查AVFoundation框架是否可用
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL available = NSClassFromString(@"AVMutableComposition") != nil &&
                        NSClassFromString(@"AVAssetExportSession") != nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(available);
        });
    });
}

- (BOOL)supportsFeature:(NSString *)feature {
    static NSSet<NSString *> *supportedFeatures = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportedFeatures = [NSSet setWithArray:@[
            M3U8VideoProcessorFeatureHardwareAcceleration,
            M3U8VideoProcessorFeatureAudioMixing,
            M3U8VideoProcessorFeatureVideoComposition,
            M3U8VideoProcessorFeatureResolutionScaling,
            M3U8VideoProcessorFeatureBatchProcessing,
            M3U8VideoProcessorFeatureCancellation,
            M3U8VideoProcessorFeatureMetadataWriting
        ]];
    });
    
    return [supportedFeatures containsObject:feature];
}

- (void)mergeWithRequest:(M3U8MergeRequest *)request
              completion:(void (^)(M3U8MergeResult * _Nullable, NSError * _Nullable))completion {
    if (!completion) {
        return;
    }
    
    // 验证请求
    NSError *validationError = nil;
    if (![request validateWithError:&validationError]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, validationError);
        });
        return;
    }
    
    // 创建统计对象
    M3U8MergeStatistics *statistics = [[M3U8MergeStatistics alloc] init];
    statistics.processorName = self.name;
    statistics.inputFileCount = request.inputFiles.count;
    statistics.startTime = [NSDate date];
    statistics.hardwareAccelerated = YES;
    
    // 在后台队列执行合并
    dispatch_async(self.processingQueue, ^{
        [self performMergeWithRequest:request
                           statistics:statistics
                           completion:completion];
    });
}

#pragma mark - Core Merge Logic

- (void)performMergeWithRequest:(M3U8MergeRequest *)request
                     statistics:(M3U8MergeStatistics *)statistics
                     completion:(void (^)(M3U8MergeResult * _Nullable, NSError * _Nullable))completion {
    
    M3U8MergeOptions *options = request.options ?: [M3U8MergeOptions defaultOptions];
    
    // 检查是否需要分批处理
    if (request.inputFiles.count > options.batchSize) {
        statistics.batchCount = (request.inputFiles.count + options.batchSize - 1) / options.batchSize;
        [self performBatchMergeWithRequest:request
                                statistics:statistics
                                completion:completion];
    } else {
        statistics.batchCount = 1;
        [self performSingleMergeWithFiles:request.inputFiles
                                outputURL:request.outputURL
                                  options:options
                          cancellationToken:request.cancellationToken
                          progressHandler:request.progressHandler
                               statistics:statistics
                               completion:completion];
    }
}

- (void)performSingleMergeWithFiles:(NSArray<NSURL *> *)inputFiles
                          outputURL:(NSURL *)outputURL
                            options:(M3U8MergeOptions *)options
                  cancellationToken:(M3U8CancellationToken *)cancellationToken
                    progressHandler:(void (^)(double))progressHandler
                         statistics:(M3U8MergeStatistics *)statistics
                         completion:(void (^)(M3U8MergeResult * _Nullable, NSError * _Nullable))completion {
    
    // 检查取消
    if (cancellationToken.isCancelled) {
        [self completeWithCancellation:statistics completion:completion];
        return;
    }
    
    // 创建composition
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = nil;
    AVMutableCompositionTrack *audioTrack = nil;
    
    CMTime currentTime = kCMTimeZero;
    NSInteger processedCount = 0;
    
    // 计算输入文件总大小
    int64_t totalInputSize = 0;
    for (NSURL *fileURL in inputFiles) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil];
        totalInputSize += [attributes[NSFileSize] longLongValue];
    }
    statistics.totalInputSize = totalInputSize;
    
    // 遍历所有输入文件
    for (NSURL *fileURL in inputFiles) {
        @autoreleasepool {
            // 检查取消
            if (cancellationToken.isCancelled) {
                [self completeWithCancellation:statistics completion:completion];
                return;
            }
            
            // 加载asset
            AVAsset *asset = [AVAsset assetWithURL:fileURL];
            
            // 获取视频轨道
            NSArray<AVAssetTrack *> *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if (videoTracks.count > 0) {
                AVAssetTrack *assetVideoTrack = videoTracks.firstObject;
                
                // 创建composition视频轨道（如果还没有）
                if (!videoTrack) {
                    videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                          preferredTrackID:kCMPersistentTrackID_Invalid];
                }
                
                // 插入视频轨道
                NSError *error = nil;
                CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
                [videoTrack insertTimeRange:timeRange
                                    ofTrack:assetVideoTrack
                                     atTime:currentTime
                                      error:&error];
                
                if (error) {
                    [self completeWithError:error statistics:statistics completion:completion];
                    return;
                }
            }
            
            // 获取音频轨道
            NSArray<AVAssetTrack *> *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            if (audioTracks.count > 0) {
                AVAssetTrack *assetAudioTrack = audioTracks.firstObject;
                
                // 创建composition音频轨道（如果还没有）
                if (!audioTrack) {
                    audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                          preferredTrackID:kCMPersistentTrackID_Invalid];
                }
                
                // 插入音频轨道
                NSError *error = nil;
                CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
                [audioTrack insertTimeRange:timeRange
                                    ofTrack:assetAudioTrack
                                     atTime:currentTime
                                      error:&error];
                
                if (error) {
                    [self completeWithError:error statistics:statistics completion:completion];
                    return;
                }
            }
            
            // 更新时间
            currentTime = CMTimeAdd(currentTime, asset.duration);
            
            // 更新进度
            processedCount++;
            if (progressHandler) {
                double progress = (double)processedCount / inputFiles.count;
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressHandler(progress);
                });
            }
        }
    }
    
    // 检查取消
    if (cancellationToken.isCancelled) {
        [self completeWithCancellation:statistics completion:completion];
        return;
    }
    
    // 导出composition
    [self exportComposition:composition
                  toURL:outputURL
                options:options
      cancellationToken:cancellationToken
             statistics:statistics
             completion:completion];
}

- (void)exportComposition:(AVMutableComposition *)composition
                    toURL:(NSURL *)outputURL
                  options:(M3U8MergeOptions *)options
        cancellationToken:(M3U8CancellationToken *)cancellationToken
               statistics:(M3U8MergeStatistics *)statistics
               completion:(void (^)(M3U8MergeResult * _Nullable, NSError * _Nullable))completion {
    
    // 删除已存在的输出文件
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    
    // 确定导出预设
    NSString *presetName = options.exportPreset ?: AVAssetExportPresetPassthrough;
    
    // 创建导出会话
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition
                                                                            presetName:presetName];
    if (!exportSession) {
        NSError *error = [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                             code:2001
                                         userInfo:@{NSLocalizedDescriptionKey: @"无法创建导出会话"}];
        [self completeWithError:error statistics:statistics completion:completion];
        return;
    }
    
    // 配置导出会话
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = [self outputFileTypeForFormat:options.outputFormat];
    exportSession.shouldOptimizeForNetworkUse = options.optimizeForNetworkUse;
    
    // 检查是否需要处理分辨率不一致
    if (options.scalingStrategy != M3U8ScalingStrategyNone) {
        CGSize targetSize = [self detectResolutionInconsistency:statistics.inputFileCount > 0 ? @[] : @[]];
        if (!CGSizeEqualToSize(targetSize, CGSizeZero)) {
            AVVideoComposition *videoComposition = [self createVideoCompositionForSize:targetSize
                                                                           composition:composition
                                                                        scalingStrategy:options.scalingStrategy];
            if (videoComposition) {
                exportSession.videoComposition = videoComposition;
                if (options.verboseLogging) {
                    NSLog(@"[AVFoundation] 应用视频组合以处理分辨率不一致，目标尺寸: %.0fx%.0f",
                          targetSize.width, targetSize.height);
                }
            }
        }
    }
    
    // 设置元数据
    if (options.writeMetadata && options.metadata) {
        NSMutableArray<AVMetadataItem *> *metadataItems = [NSMutableArray array];
        for (NSString *key in options.metadata) {
            AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
            item.keySpace = AVMetadataKeySpaceCommon;
            item.key = key;
            item.value = options.metadata[key];
            [metadataItems addObject:item];
        }
        exportSession.metadata = metadataItems;
    }
    
    // 注册取消处理
    if (cancellationToken) {
        [cancellationToken registerCancellationHandler:^{
            [exportSession cancelExport];
        }];
    }
    
    // 执行导出
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(self.processingQueue, ^{
            if (cancellationToken.isCancelled || exportSession.status == AVAssetExportSessionStatusCancelled) {
                [self completeWithCancellation:statistics completion:completion];
                return;
            }
            
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                // 获取输出文件大小
                NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:outputURL.path error:nil];
                statistics.outputSize = [attributes[NSFileSize] longLongValue];
                
                // 计算统计信息
                statistics.endTime = [NSDate date];
                statistics.totalDuration = [statistics.endTime timeIntervalSinceDate:statistics.startTime];
                statistics.averageSpeed = (statistics.totalInputSize / 1024.0 / 1024.0) / statistics.totalDuration;
                statistics.peakMemoryUsage = [self getCurrentMemoryUsage];
                
                // 获取视频时长
                AVAsset *outputAsset = [AVAsset assetWithURL:outputURL];
                NSTimeInterval duration = CMTimeGetSeconds(outputAsset.duration);
                
                M3U8MergeResult *result = [M3U8MergeResult successWithOutputURL:outputURL
                                                                        duration:duration
                                                                   processorName:self.name
                                                                      statistics:statistics];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(result, nil);
                });
            } else {
                NSError *error = exportSession.error ?: [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                                                             code:2002
                                                                         userInfo:@{NSLocalizedDescriptionKey: @"导出失败"}];
                [self completeWithError:error statistics:statistics completion:completion];
            }
        });
    }];
}

#pragma mark - Batch Processing

- (void)performBatchMergeWithRequest:(M3U8MergeRequest *)request
                          statistics:(M3U8MergeStatistics *)statistics
                          completion:(void (^)(M3U8MergeResult * _Nullable, NSError * _Nullable))completion {
    
    M3U8MergeOptions *options = request.options ?: [M3U8MergeOptions defaultOptions];
    NSInteger batchSize = options.batchSize;
    NSInteger totalFiles = request.inputFiles.count;
    NSInteger batchCount = (totalFiles + batchSize - 1) / batchSize;
    
    if (options.verboseLogging) {
        NSLog(@"[AVFoundation] 开始分批处理: %ld 个文件，分为 %ld 批", (long)totalFiles, (long)batchCount);
    }
    
    // 创建临时目录
    NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSMutableArray<NSURL *> *batchOutputs = [NSMutableArray array];
    __block NSInteger completedBatches = 0;
    __block BOOL hasError = NO;
    __block NSError *batchError = nil;
    
    dispatch_group_t group = dispatch_group_create();
    
    // 处理每一批
    for (NSInteger i = 0; i < batchCount; i++) {
        if (hasError || request.cancellationToken.isCancelled) {
            break;
        }
        
        NSInteger startIndex = i * batchSize;
        NSInteger endIndex = MIN(startIndex + batchSize, totalFiles);
        NSArray<NSURL *> *batchFiles = [request.inputFiles subarrayWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
        
        // 创建临时输出文件
        NSString *batchFileName = [NSString stringWithFormat:@"batch_%ld.mp4", (long)i];
        NSURL *batchOutputURL = [NSURL fileURLWithPath:[tempDir stringByAppendingPathComponent:batchFileName]];
        [batchOutputs addObject:batchOutputURL];
        [self.temporaryFiles addObject:batchOutputURL];
        
        dispatch_group_enter(group);
        
        // 合并这一批
        [self performSingleMergeWithFiles:batchFiles
                                outputURL:batchOutputURL
                                  options:options
                        cancellationToken:request.cancellationToken
                          progressHandler:^(double batchProgress) {
            // 计算总进度
            double overallProgress = ((double)completedBatches + batchProgress) / batchCount;
            if (request.progressHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    request.progressHandler(overallProgress);
                });
            }
        }
                               statistics:[[M3U8MergeStatistics alloc] init]
                               completion:^(M3U8MergeResult * _Nullable result, NSError * _Nullable error) {
            if (error) {
                hasError = YES;
                batchError = error;
            } else {
                completedBatches++;
            }
            dispatch_group_leave(group);
        }];
    }
    
    // 等待所有批次完成
    dispatch_group_notify(group, self.processingQueue, ^{
        if (hasError) {
            [self cleanupTemporaryFiles];
            [self completeWithError:batchError statistics:statistics completion:completion];
            return;
        }
        
        if (request.cancellationToken.isCancelled) {
            [self cleanupTemporaryFiles];
            [self completeWithCancellation:statistics completion:completion];
            return;
        }
        
        // 合并所有批次输出
        [self performSingleMergeWithFiles:batchOutputs
                                outputURL:request.outputURL
                                  options:options
                        cancellationToken:request.cancellationToken
                          progressHandler:request.progressHandler
                               statistics:statistics
                               completion:^(M3U8MergeResult * _Nullable result, NSError * _Nullable error) {
            [self cleanupTemporaryFiles];
            
            if (error) {
                [self completeWithError:error statistics:statistics completion:completion];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(result, nil);
                });
            }
        }];
    });
}

#pragma mark - Helper Methods

- (AVFileType)outputFileTypeForFormat:(M3U8OutputFormat)format {
    switch (format) {
        case M3U8OutputFormatMP4:
            return AVFileTypeMPEG4;
        case M3U8OutputFormatMOV:
            return AVFileTypeQuickTimeMovie;
        case M3U8OutputFormatM4V:
            return AVFileTypeAppleM4V;
        case M3U8OutputFormatAuto:
        default:
            return AVFileTypeMPEG4;
    }
}

- (int64_t)getCurrentMemoryUsage {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    if (kerr == KERN_SUCCESS) {
        return info.resident_size;
    }
    return 0;
}

- (void)cleanupTemporaryFiles {
    for (NSURL *fileURL in self.temporaryFiles) {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    }
    [self.temporaryFiles removeAllObjects];
}

- (void)completeWithError:(NSError *)error
               statistics:(M3U8MergeStatistics *)statistics
               completion:(void (^)(M3U8MergeResult * _Nullable, NSError * _Nullable))completion {
    statistics.endTime = [NSDate date];
    statistics.totalDuration = [statistics.endTime timeIntervalSinceDate:statistics.startTime];
    
    M3U8MergeResult *result = [M3U8MergeResult failureWithError:error
                                                   processorName:self.name
                                                      statistics:statistics];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(result, error);
    });
}

- (void)completeWithCancellation:(M3U8MergeStatistics *)statistics
                      completion:(void (^)(M3U8MergeResult * _Nullable, NSError * _Nullable))completion {
    statistics.endTime = [NSDate date];
    statistics.totalDuration = [statistics.endTime timeIntervalSinceDate:statistics.startTime];
    
    M3U8MergeResult *result = [M3U8MergeResult cancelledWithProcessorName:self.name
                                                                statistics:statistics];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(result, result.error);
    });
}

#pragma mark - Resolution Handling

- (CGSize)detectResolutionInconsistency:(NSArray<NSURL *> *)inputFiles {
    if (inputFiles.count == 0) {
        return CGSizeZero;
    }
    
    CGSize firstSize = CGSizeZero;
    BOOL hasInconsistency = NO;
    
    for (NSUInteger i = 0; i < inputFiles.count; i++) {
        AVAsset *asset = [AVAsset assetWithURL:inputFiles[i]];
        NSArray<AVAssetTrack *> *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        
        if (videoTracks.count > 0) {
            AVAssetTrack *videoTrack = videoTracks.firstObject;
            CGSize naturalSize = videoTrack.naturalSize;
            
            // 考虑视频变换（旋转）
            CGAffineTransform transform = videoTrack.preferredTransform;
            CGSize transformedSize = CGSizeApplyAffineTransform(naturalSize, transform);
            transformedSize.width = fabs(transformedSize.width);
            transformedSize.height = fabs(transformedSize.height);
            
            if (i == 0) {
                firstSize = transformedSize;
            } else {
                if (!CGSizeEqualToSize(firstSize, transformedSize)) {
                    hasInconsistency = YES;
                    NSLog(@"[AVFoundation] 检测到分辨率不一致: 第一个视频 %.0fx%.0f, 第 %lu 个视频 %.0fx%.0f",
                          firstSize.width, firstSize.height, (unsigned long)(i + 1),
                          transformedSize.width, transformedSize.height);
                }
            }
        }
    }
    
    return hasInconsistency ? firstSize : CGSizeZero;
}

- (AVVideoComposition *)createVideoCompositionForSize:(CGSize)targetSize
                                          composition:(AVMutableComposition *)composition
                                       scalingStrategy:(M3U8ScalingStrategy)strategy {
    
    if (CGSizeEqualToSize(targetSize, CGSizeZero)) {
        return nil;
    }
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = targetSize;
    videoComposition.frameDuration = CMTimeMake(1, 30); // 30 FPS
    
    // 获取所有视频轨道
    NSArray<AVMutableCompositionTrack *> *videoTracks = [composition tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count == 0) {
        return nil;
    }
    
    AVMutableCompositionTrack *videoTrack = videoTracks.firstObject;
    
    // 创建视频组合指令
    NSMutableArray<AVMutableVideoCompositionInstruction *> *instructions = [NSMutableArray array];
    
    CMTime currentTime = kCMTimeZero;
    for (AVAssetTrackSegment *segment in videoTrack.segments) {
        if (segment.isEmpty) {
            continue;
        }
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(currentTime, segment.timeMapping.target.duration);
        
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        // 使用轨道的自然尺寸
        CGSize sourceSize = videoTrack.naturalSize;
        
        // 计算缩放变换
        CGAffineTransform transform = [self calculateTransformFromSize:sourceSize
                                                                 toSize:targetSize
                                                         scalingStrategy:strategy];
        
        [layerInstruction setTransform:transform atTime:currentTime];
        instruction.layerInstructions = @[layerInstruction];
        
        [instructions addObject:instruction];
        currentTime = CMTimeAdd(currentTime, segment.timeMapping.target.duration);
    }
    
    videoComposition.instructions = instructions;
    
    return videoComposition;
}

- (CGAffineTransform)calculateTransformFromSize:(CGSize)sourceSize
                                         toSize:(CGSize)targetSize
                                 scalingStrategy:(M3U8ScalingStrategy)strategy {
    
    if (CGSizeEqualToSize(sourceSize, targetSize)) {
        return CGAffineTransformIdentity;
    }
    
    CGFloat scaleX = targetSize.width / sourceSize.width;
    CGFloat scaleY = targetSize.height / sourceSize.height;
    CGFloat scale = 1.0;
    CGFloat translateX = 0;
    CGFloat translateY = 0;
    
    switch (strategy) {
        case M3U8ScalingStrategyScaleToFirst:
        case M3U8ScalingStrategyScaleToMax:
        case M3U8ScalingStrategyScaleToMin:
            // 简单缩放，可能会变形
            scale = (scaleX + scaleY) / 2.0;
            break;
            
        case M3U8ScalingStrategyAspectFit:
            // 保持宽高比，适应目标尺寸（可能有黑边）
            scale = MIN(scaleX, scaleY);
            translateX = (targetSize.width - sourceSize.width * scale) / 2.0;
            translateY = (targetSize.height - sourceSize.height * scale) / 2.0;
            break;
            
        case M3U8ScalingStrategyAspectFill:
            // 保持宽高比，填充目标尺寸（可能会裁剪）
            scale = MAX(scaleX, scaleY);
            translateX = (targetSize.width - sourceSize.width * scale) / 2.0;
            translateY = (targetSize.height - sourceSize.height * scale) / 2.0;
            break;
            
        case M3U8ScalingStrategyNone:
        default:
            return CGAffineTransformIdentity;
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, scale, scale);
    transform = CGAffineTransformTranslate(transform, translateX / scale, translateY / scale);
    
    return transform;
}

@end
