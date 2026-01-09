//
//  M3U8MergeRequest.m
//  M3U8DownloaderKit
//
//  视频合并请求实现
//

#import "M3U8MergeRequest.h"
#import "M3U8MergeOptions.h"
#import "M3U8CancellationToken.h"

@implementation M3U8MergeRequest

+ (instancetype)requestWithInputFiles:(NSArray<NSURL *> *)inputFiles
                            outputURL:(NSURL *)outputURL
                              options:(M3U8MergeOptions *)options {
    M3U8MergeRequest *request = [[self alloc] init];
    request.inputFiles = inputFiles;
    request.outputURL = outputURL;
    request.options = options ?: [M3U8MergeOptions defaultOptions];
    request.cancellationToken = [[M3U8CancellationToken alloc] init];
    return request;
}

- (BOOL)validateWithError:(NSError **)error {
    // 检查输入文件
    if (!self.inputFiles || self.inputFiles.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"输入文件列表为空"}];
        }
        return NO;
    }
    
    // 检查输入文件是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSURL *fileURL in self.inputFiles) {
        if (![fileURL isFileURL]) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                             code:1002
                                         userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"无效的文件URL: %@", fileURL]}];
            }
            return NO;
        }
        
        if (![fileManager fileExistsAtPath:fileURL.path]) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                             code:1003
                                         userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"文件不存在: %@", fileURL.path]}];
            }
            return NO;
        }
    }
    
    // 检查输出URL
    if (!self.outputURL) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                         code:1004
                                     userInfo:@{NSLocalizedDescriptionKey: @"输出URL为空"}];
        }
        return NO;
    }
    
    if (![self.outputURL isFileURL]) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                         code:1005
                                     userInfo:@{NSLocalizedDescriptionKey: @"输出URL必须是文件URL"}];
        }
        return NO;
    }
    
    // 检查输出目录是否存在
    NSString *outputDir = [self.outputURL.path stringByDeletingLastPathComponent];
    BOOL isDirectory = NO;
    if (![fileManager fileExistsAtPath:outputDir isDirectory:&isDirectory] || !isDirectory) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                         code:1006
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"输出目录不存在: %@", outputDir]}];
        }
        return NO;
    }
    
    // 检查输出目录是否可写
    if (![fileManager isWritableFileAtPath:outputDir]) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.m3u8downloader.merge"
                                         code:1007
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"输出目录不可写: %@", outputDir]}];
        }
        return NO;
    }
    
    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<M3U8MergeRequest: inputs=%lu files, output=%@>",
            (unsigned long)self.inputFiles.count, self.outputURL.lastPathComponent];
}

@end
