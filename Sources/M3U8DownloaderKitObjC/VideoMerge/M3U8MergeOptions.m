//
//  M3U8MergeOptions.m
//  M3U8DownloaderKit
//
//  视频合并配置选项实现
//

#import "M3U8MergeOptions.h"
#import <TargetConditionals.h>

@implementation M3U8MergeOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置默认值
        _outputFormat = M3U8OutputFormatMP4;
        _videoCodec = nil;
        _audioCodec = nil;
        _useAACFilter = YES;
        _writeMetadata = YES;
        _metadata = nil;
        
        // 根据平台设置默认批次大小
#if TARGET_OS_IOS
        _batchSize = 100;
#elif TARGET_OS_OSX
        _batchSize = 200;
#else
        _batchSize = 100;
#endif
        
        _scalingStrategy = M3U8ScalingStrategyScaleToFirst;
        _optimizeForNetworkUse = YES;
        _exportPreset = nil;
        _maxRetryCount = 3;
        _retryDelay = 1.0;
        _verboseLogging = NO;
    }
    return self;
}

+ (instancetype)defaultOptions {
    return [[self alloc] init];
}

- (id)copyWithZone:(NSZone *)zone {
    M3U8MergeOptions *copy = [[M3U8MergeOptions allocWithZone:zone] init];
    copy.outputFormat = self.outputFormat;
    copy.videoCodec = self.videoCodec;
    copy.audioCodec = self.audioCodec;
    copy.useAACFilter = self.useAACFilter;
    copy.writeMetadata = self.writeMetadata;
    copy.metadata = self.metadata;
    copy.batchSize = self.batchSize;
    copy.scalingStrategy = self.scalingStrategy;
    copy.optimizeForNetworkUse = self.optimizeForNetworkUse;
    copy.exportPreset = self.exportPreset;
    copy.maxRetryCount = self.maxRetryCount;
    copy.retryDelay = self.retryDelay;
    copy.verboseLogging = self.verboseLogging;
    return copy;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<M3U8MergeOptions: outputFormat=%ld, batchSize=%ld, scalingStrategy=%ld>",
            (long)self.outputFormat, (long)self.batchSize, (long)self.scalingStrategy];
}

@end
