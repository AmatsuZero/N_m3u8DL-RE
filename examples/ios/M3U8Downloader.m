//
//  M3U8Downloader.m
//  N_m3u8DL-RE iOS Example
//
//  Objective-C wrapper for N_m3u8DL_RE_Core library
//

#import "M3U8Downloader.h"
#import <N_m3u8DL_RE_Core/N_m3u8DL_RE_Core.h>

@interface M3U8Downloader ()

@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, copy, nullable) M3U8DownloadProgressBlock progressBlock;
@property (nonatomic, copy, nullable) M3U8DownloadCompletionBlock completionBlock;

@end

@implementation M3U8Downloader

#pragma mark - Singleton

+ (instancetype)sharedDownloader {
    static M3U8Downloader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化库
        int result = m3u8dl_init();
        if (result != 0) {
            NSLog(@"[M3U8Downloader] Failed to initialize library: %d", result);
        }
        
        // 创建下载队列
        _downloadQueue = dispatch_queue_create("com.n-m3u8dl-re.download", DISPATCH_QUEUE_SERIAL);
        _isCancelled = NO;
    }
    return self;
}

- (void)dealloc {
    [self cancel];
}

#pragma mark - Public Methods

- (void)downloadURL:(NSString *)url
         outputPath:(NSString *)outputPath
         onProgress:(nullable M3U8DownloadProgressBlock)progressBlock
       onCompletion:(M3U8DownloadCompletionBlock)completionBlock {
    
    if (!url || url.length == 0) {
        NSError *error = [NSError errorWithDomain:@"M3U8DownloaderErrorDomain"
                                             code:-2
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        if (completionBlock) {
            completionBlock(NO, nil, error);
        }
        return;
    }
    
    if (!outputPath || outputPath.length == 0) {
        NSError *error = [NSError errorWithDomain:@"M3U8DownloaderErrorDomain"
                                             code:-3
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid output path"}];
        if (completionBlock) {
            completionBlock(NO, nil, error);
        }
        return;
    }
    
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;
    self.isCancelled = NO;
    
    const char *urlCStr = [url UTF8String];
    const char *pathCStr = [outputPath UTF8String];
    
    dispatch_async(self.downloadQueue, ^{
        // 启动下载
        int result = m3u8dl_download(urlCStr, pathCStr, ^(int res, const char* output) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.completionBlock) {
                    if (res == 0) {
                        NSString *outputStr = output ? [NSString stringWithUTF8String:output] : outputPath;
                        self.completionBlock(YES, outputStr, nil);
                    } else {
                        NSError *error = [NSError errorWithDomain:@"M3U8DownloaderErrorDomain"
                                                             code:res
                                                         userInfo:@{NSLocalizedDescriptionKey: @"Download failed"}];
                        self.completionBlock(NO, nil, error);
                    }
                }
            });
        });
        
        if (result != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.completionBlock) {
                    NSError *error = [NSError errorWithDomain:@"M3U8DownloaderErrorDomain"
                                                         code:result
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to start download"}];
                    self.completionBlock(NO, nil, error);
                }
            });
            return;
        }
        
        // 监控进度
        while (!self.isCancelled) {
            int progress = m3u8dl_get_progress();
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.progressBlock) {
                    // TODO: 获取实际的下载字节数
                    self.progressBlock(progress, 0, 0);
                }
            });
            
            if (progress >= 100) {
                break;
            }
            
            [NSThread sleepForTimeInterval:0.5];
        }
    });
}

- (void)cancel {
    self.isCancelled = YES;
    m3u8dl_cancel();
}

- (int)currentProgress {
    return m3u8dl_get_progress();
}

- (NSString *)libraryVersion {
    const char *version = m3u8dl_get_version();
    if (version) {
        NSString *versionStr = [NSString stringWithUTF8String:version];
        m3u8dl_free_string(version);
        return versionStr;
    }
    return @"Unknown";
}

- (NSString *)apiVersion {
    int version = m3u8dl_get_api_version();
    int major = (version >> 16) & 0xFF;
    int minor = (version >> 8) & 0xFF;
    int patch = version & 0xFF;
    return [NSString stringWithFormat:@"%d.%d.%d", major, minor, patch];
}

@end
