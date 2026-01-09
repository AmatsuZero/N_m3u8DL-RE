//
//  M3U8Types.m
//  M3U8DownloaderKit
//
//  数据模型类实现
//

#import "M3U8Types.h"

#pragma mark - M3U8Configuration

@implementation M3U8Configuration

+ (instancetype)defaultConfiguration {
    M3U8Configuration *config = [[M3U8Configuration alloc] init];
    config.threadCount = 4;
    config.connectionTimeout = 30;
    config.readTimeout = 60;
    config.maxRetryCount = 3;
    config.tempDirectory = nil;
    return config;
}

- (NSString *)toJSONString {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"threadCount"] = @(self.threadCount);
    dict[@"connectionTimeout"] = @(self.connectionTimeout);
    dict[@"readTimeout"] = @(self.readTimeout);
    dict[@"maxRetryCount"] = @(self.maxRetryCount);
    if (self.tempDirectory) {
        dict[@"tempDirectory"] = self.tempDirectory;
    }
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (error || !data) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - M3U8DownloadOptions

@implementation M3U8DownloadOptions

+ (instancetype)defaultOptions {
    M3U8DownloadOptions *options = [[M3U8DownloadOptions alloc] init];
    options.autoSelectBestQuality = YES;
    options.selectedVideoStreamIndex = -1;
    options.selectedAudioStreamIndex = -1;
    return options;
}

@end

#pragma mark - M3U8StreamInfo

@implementation M3U8StreamInfo

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        NSString *typeStr = dict[@"type"];
        if ([typeStr isEqualToString:@"video"]) {
            _type = M3U8StreamTypeVideo;
        } else if ([typeStr isEqualToString:@"audio"]) {
            _type = M3U8StreamTypeAudio;
        } else if ([typeStr isEqualToString:@"subtitle"]) {
            _type = M3U8StreamTypeSubtitle;
        }
        
        _resolution = dict[@"resolution"];
        _bandwidth = [dict[@"bandwidth"] integerValue];
        _codecs = dict[@"codecs"];
        _frameRate = [dict[@"frameRate"] doubleValue];
        _language = dict[@"language"];
        _name = dict[@"name"];
    }
    return self;
}

@end

#pragma mark - M3U8ParseResult

@implementation M3U8ParseResult

+ (instancetype)parseFromJSONString:(NSString *)jsonString {
    if (!jsonString) return nil;
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    M3U8ParseResult *result = [[M3U8ParseResult alloc] init];
    result.success = [dict[@"success"] boolValue];
    result.errorMessage = dict[@"errorMessage"];
    result.isLive = [dict[@"isLive"] boolValue];
    result.duration = [dict[@"duration"] doubleValue];
    
    NSArray *streamsArray = dict[@"streams"];
    if ([streamsArray isKindOfClass:[NSArray class]]) {
        NSMutableArray *streams = [NSMutableArray array];
        for (NSDictionary *streamDict in streamsArray) {
            if ([streamDict isKindOfClass:[NSDictionary class]]) {
                M3U8StreamInfo *info = [[M3U8StreamInfo alloc] initWithDictionary:streamDict];
                [streams addObject:info];
            }
        }
        result.streams = [streams copy];
    } else {
        result.streams = @[];
    }
    
    return result;
}

@end

#pragma mark - M3U8DownloadProgress

@implementation M3U8DownloadProgress

+ (instancetype)parseFromJSONString:(NSString *)jsonString {
    if (!jsonString) return nil;
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    M3U8DownloadProgress *progress = [[M3U8DownloadProgress alloc] init];
    progress.percentage = [dict[@"percentage"] integerValue];
    progress.status = [dict[@"status"] integerValue];
    progress.downloadedBytes = [dict[@"downloadedBytes"] longLongValue];
    progress.totalBytes = [dict[@"totalBytes"] longLongValue];
    progress.speed = [dict[@"speed"] longLongValue];
    progress.downloadedSegments = [dict[@"downloadedSegments"] integerValue];
    progress.totalSegments = [dict[@"totalSegments"] integerValue];
    progress.currentTask = dict[@"currentTask"];
    
    return progress;
}

@end

#pragma mark - M3U8DownloadResult

@implementation M3U8DownloadResult

+ (instancetype)parseFromJSONString:(NSString *)jsonString {
    if (!jsonString) return nil;
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    M3U8DownloadResult *result = [[M3U8DownloadResult alloc] init];
    result.success = [dict[@"success"] boolValue];
    result.errorMessage = dict[@"errorMessage"];
    result.outputFile = dict[@"outputFile"];
    result.fileSize = [dict[@"fileSize"] longLongValue];
    result.duration = [dict[@"duration"] doubleValue];
    
    return result;
}

@end

#pragma mark - M3U8VersionInfo

@implementation M3U8VersionInfo

+ (instancetype)parseFromJSONString:(NSString *)jsonString {
    if (!jsonString) return nil;
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    M3U8VersionInfo *info = [[M3U8VersionInfo alloc] init];
    info.version = dict[@"version"] ?: @"unknown";
    info.buildDate = dict[@"buildDate"];
    info.supportedFeatures = dict[@"supportedFeatures"] ?: @[];
    
    return info;
}

@end
