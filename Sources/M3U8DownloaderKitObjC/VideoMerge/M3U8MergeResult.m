//
//  M3U8MergeResult.m
//  M3U8DownloaderKit
//
//  视频合并结果实现
//

#import "M3U8MergeResult.h"
#import "M3U8MergeStatistics.h"

@implementation M3U8MergeResult

+ (instancetype)successWithOutputURL:(NSURL *)outputURL
                            duration:(NSTimeInterval)duration
                       processorName:(NSString *)processorName
                          statistics:(M3U8MergeStatistics *)statistics {
    M3U8MergeResult *result = [[self alloc] init];
    result.success = YES;
    result.outputURL = outputURL;
    result.duration = duration;
    result.processorName = processorName;
    result.statistics = statistics;
    result.cancelled = NO;
    result.error = nil;
    return result;
}

+ (instancetype)failureWithError:(NSError *)error
                   processorName:(NSString *)processorName
                      statistics:(M3U8MergeStatistics *)statistics {
    M3U8MergeResult *result = [[self alloc] init];
    result.success = NO;
    result.outputURL = nil;
    result.duration = 0;
    result.processorName = processorName;
    result.statistics = statistics;
    result.cancelled = NO;
    result.error = error;
    return result;
}

+ (instancetype)cancelledWithProcessorName:(NSString *)processorName
                                statistics:(M3U8MergeStatistics *)statistics {
    M3U8MergeResult *result = [[self alloc] init];
    result.success = NO;
    result.outputURL = nil;
    result.duration = 0;
    result.processorName = processorName;
    result.statistics = statistics;
    result.cancelled = YES;
    result.error = [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                       code:-999
                                   userInfo:@{NSLocalizedDescriptionKey: @"操作已取消"}];
    return result;
}

- (NSString *)description {
    if (self.success) {
        return [NSString stringWithFormat:@"<M3U8MergeResult: success, output=%@, duration=%.2fs>",
                self.outputURL.path, self.duration];
    } else if (self.cancelled) {
        return @"<M3U8MergeResult: cancelled>";
    } else {
        return [NSString stringWithFormat:@"<M3U8MergeResult: failure, error=%@>", self.error.localizedDescription];
    }
}

@end
