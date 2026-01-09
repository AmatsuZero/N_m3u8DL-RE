//
//  M3U8MergeStatistics.m
//  M3U8DownloaderKit
//
//  视频合并统计信息实现
//

#import "M3U8MergeStatistics.h"

@implementation M3U8MergeStatistics

- (instancetype)init {
    self = [super init];
    if (self) {
        _totalDuration = 0;
        _inputFileCount = 0;
        _totalInputSize = 0;
        _outputSize = 0;
        _averageSpeed = 0;
        _peakMemoryUsage = 0;
        _batchCount = 1;
        _processorName = @"Unknown";
        _hardwareAccelerated = NO;
        _startTime = [NSDate date];
        _endTime = nil;
    }
    return self;
}

- (NSString *)formattedDescription {
    NSMutableString *desc = [NSMutableString string];
    
    [desc appendFormat:@"视频合并统计信息:\n"];
    [desc appendFormat:@"  处理器: %@\n", self.processorName];
    [desc appendFormat:@"  输入文件: %ld 个\n", (long)self.inputFileCount];
    [desc appendFormat:@"  输入大小: %.2f MB\n", self.totalInputSize / 1024.0 / 1024.0];
    [desc appendFormat:@"  输出大小: %.2f MB\n", self.outputSize / 1024.0 / 1024.0];
    [desc appendFormat:@"  总耗时: %.2f 秒\n", self.totalDuration];
    [desc appendFormat:@"  平均速度: %.2f MB/s\n", self.averageSpeed];
    [desc appendFormat:@"  峰值内存: %.2f MB\n", self.peakMemoryUsage / 1024.0 / 1024.0];
    [desc appendFormat:@"  批次数量: %ld\n", (long)self.batchCount];
    [desc appendFormat:@"  硬件加速: %@\n", self.hardwareAccelerated ? @"是" : @"否"];
    
    return desc;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<M3U8MergeStatistics: processor=%@, files=%ld, duration=%.2fs, speed=%.2fMB/s>",
            self.processorName, (long)self.inputFileCount, self.totalDuration, self.averageSpeed];
}

@end
