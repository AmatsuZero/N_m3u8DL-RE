//
//  M3U8Downloader.m
//  M3U8DownloaderKit
//
//  主下载器类实现
//

#import "M3U8Downloader.h"

// 直接导入 C 头文件（ObjC 与 C 完全兼容）
#include "m3u8dl.h"

#pragma mark - M3U8Downloader 私有接口（前向声明）

// 必须在 C 回调函数之前声明，否则编译器找不到方法
@interface M3U8Downloader ()

/// 内部实例 ID
@property (nonatomic, assign) m3u8dl_instance_t instanceId;

/// 是否已释放
@property (nonatomic, assign, readwrite) BOOL isDisposed;

/// 当前状态
@property (nonatomic, assign, readwrite) M3U8DownloadStatus currentStatus;

/// 进度回调 Block
@property (nonatomic, copy, nullable) M3U8ProgressBlock progressBlock;

/// 完成回调 Block
@property (nonatomic, copy, nullable) M3U8DownloadCompletionBlock completionBlock;

/// 日志回调 Block
@property (nonatomic, copy, nullable) M3U8LogBlock logBlock;

/// 状态锁
@property (nonatomic, strong) NSLock *lock;

/// 处理进度回调
- (void)handleProgress:(M3U8DownloadProgress *)progress;

/// 处理完成回调
- (void)handleCompletion:(M3U8DownloadResult *)result;

/// 处理日志回调
- (void)handleLog:(M3U8LogLevel)level message:(NSString *)message;

@end

#pragma mark - 静态变量

/// 全局实例映射
static NSMutableDictionary<NSNumber *, M3U8Downloader *> *s_instances = nil;

/// 实例映射锁
static NSLock *s_instancesLock = nil;

/// 回调是否已设置
static BOOL s_callbacksSetup = NO;

#pragma mark - C 回调函数

static void globalProgressCallback(m3u8dl_instance_t instanceId, int32_t percentage, const char *statusJson) {
    if (!statusJson) return;
    
    NSString *jsonString = [NSString stringWithUTF8String:statusJson];
    M3U8DownloadProgress *progress = [M3U8DownloadProgress parseFromJSONString:jsonString];
    if (!progress) return;
    
    // 更新百分比（C API 传递的）
    progress.percentage = percentage;
    
    [s_instancesLock lock];
    M3U8Downloader *instance = s_instances[@(instanceId)];
    [s_instancesLock unlock];
    
    if (instance) {
        [instance handleProgress:progress];
    }
}

static void globalCompletionCallback(m3u8dl_instance_t instanceId, m3u8dl_bool_t success, const char *resultJson) {
    if (!resultJson) return;
    
    NSString *jsonString = [NSString stringWithUTF8String:resultJson];
    M3U8DownloadResult *result = [M3U8DownloadResult parseFromJSONString:jsonString];
    if (!result) {
        result = [[M3U8DownloadResult alloc] init];
        result.success = (success != 0);
    }
    
    [s_instancesLock lock];
    M3U8Downloader *instance = s_instances[@(instanceId)];
    [s_instancesLock unlock];
    
    if (instance) {
        [instance handleCompletion:result];
    }
}

static void globalLogCallback(m3u8dl_log_level_t level, const char *message) {
    if (!message) return;
    
    NSString *messageString = [NSString stringWithUTF8String:message];
    M3U8LogLevel logLevel = (M3U8LogLevel)level;
    
    // 分发到所有实例
    [s_instancesLock lock];
    NSArray *allInstances = [s_instances.allValues copy];
    [s_instancesLock unlock];
    
    for (M3U8Downloader *instance in allInstances) {
        [instance handleLog:logLevel message:messageString];
    }
}

#pragma mark - M3U8Downloader 实现

@implementation M3U8Downloader

#pragma mark - 类方法

+ (void)initialize {
    if (self == [M3U8Downloader class]) {
        s_instances = [NSMutableDictionary dictionary];
        s_instancesLock = [[NSLock alloc] init];
    }
}

+ (void)setupGlobalCallbacks {
    if (s_callbacksSetup) return;
    s_callbacksSetup = YES;
    
    m3u8dl_set_progress_callback(globalProgressCallback);
    m3u8dl_set_completion_callback(globalCompletionCallback);
    m3u8dl_set_log_callback(globalLogCallback);
}

+ (void)registerInstance:(M3U8Downloader *)instance {
    [s_instancesLock lock];
    s_instances[@(instance.instanceId)] = instance;
    [s_instancesLock unlock];
}

+ (void)unregisterInstance:(m3u8dl_instance_t)instanceId {
    [s_instancesLock lock];
    [s_instances removeObjectForKey:@(instanceId)];
    [s_instancesLock unlock];
}

+ (M3U8VersionInfo *)versionInfo {
    char *resultPtr = m3u8dl_get_version();
    if (!resultPtr) return nil;
    
    NSString *jsonString = [NSString stringWithUTF8String:resultPtr];
    m3u8dl_free_string(resultPtr);
    
    return [M3U8VersionInfo parseFromJSONString:jsonString];
}

+ (void)disposeAll {
    m3u8dl_dispose_all();
    
    [s_instancesLock lock];
    for (M3U8Downloader *instance in s_instances.allValues) {
        instance.isDisposed = YES;
    }
    [s_instances removeAllObjects];
    [s_instancesLock unlock];
}

#pragma mark - 初始化

- (instancetype)initWithError:(NSError **)error {
    return [self initWithConfiguration:nil error:error];
}

- (instancetype)initWithConfiguration:(M3U8Configuration *)configuration error:(NSError **)error {
    self = [super init];
    if (self) {
        // 设置全局回调
        [[self class] setupGlobalCallbacks];
        
        _lock = [[NSLock alloc] init];
        _isDisposed = NO;
        _currentStatus = M3U8DownloadStatusIdle;
        
        // 初始化 C 库
        const char *configJson = NULL;
        NSString *configString = [configuration toJSONString];
        if (configString) {
            configJson = [configString UTF8String];
        }
        
        m3u8dl_instance_t instanceId = m3u8dl_init(configJson);
        if (instanceId <= 0) {
            if (error) {
                *error = M3U8ErrorMake(M3U8ErrorCodeInitializationFailed, @"Failed to initialize C library");
            }
            return nil;
        }
        
        _instanceId = instanceId;
        
        // 注册实例
        [[self class] registerInstance:self];
    }
    return self;
}

- (void)dealloc {
    [self dispose];
}

#pragma mark - 解析方法

- (M3U8ParseResult *)parseURL:(NSString *)url error:(NSError **)error {
    if (![self checkDisposed:error]) return nil;
    
    if (!url || url.length == 0) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeInvalidParameter, @"URL cannot be empty");
        }
        return nil;
    }
    
    char *resultPtr = m3u8dl_parse(self.instanceId, [url UTF8String]);
    if (!resultPtr) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeParseFailed, @"Parse returned no result");
        }
        return nil;
    }
    
    NSString *jsonString = [NSString stringWithUTF8String:resultPtr];
    m3u8dl_free_string(resultPtr);
    
    M3U8ParseResult *result = [M3U8ParseResult parseFromJSONString:jsonString];
    if (!result) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeJSONError, @"Failed to parse JSON response");
        }
        return nil;
    }
    
    if (!result.success) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeParseFailed, result.errorMessage ?: @"Unknown error");
        }
        return nil;
    }
    
    return result;
}

- (void)parseURL:(NSString *)url completion:(M3U8ParseCompletionBlock)completion {
    if (!completion) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        M3U8ParseResult *result = [self parseURL:url error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, error);
        });
    });
}

#pragma mark - 下载方法

- (M3U8DownloadResult *)downloadURL:(NSString *)url
                             toPath:(NSString *)outputPath
                            options:(M3U8DownloadOptions *)options
                              error:(NSError **)error {
    if (![self checkDisposed:error]) return nil;
    
    if (!url || url.length == 0) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeInvalidParameter, @"URL cannot be empty");
        }
        return nil;
    }
    
    if (!outputPath || outputPath.length == 0) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeInvalidParameter, @"Output path cannot be empty");
        }
        return nil;
    }
    
    // 构建请求 JSON
    NSMutableDictionary *request = [NSMutableDictionary dictionary];
    request[@"url"] = url;
    request[@"outputPath"] = outputPath;
    
    if (options) {
        request[@"autoSelectBestQuality"] = @(options.autoSelectBestQuality);
        if (options.customHeaders) {
            request[@"customHeaders"] = options.customHeaders;
        }
        if (options.decryptionKeys) {
            request[@"decryptionKeys"] = options.decryptionKeys;
        }
    }
    
    NSError *jsonError = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:request options:0 error:&jsonError];
    if (jsonError || !requestData) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeJSONError, @"Failed to serialize request");
        }
        return nil;
    }
    
    NSString *requestJson = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    
    [self.lock lock];
    self.currentStatus = M3U8DownloadStatusDownloading;
    [self.lock unlock];
    
    char *resultPtr = m3u8dl_download(self.instanceId, [requestJson UTF8String]);
    
    [self.lock lock];
    self.currentStatus = M3U8DownloadStatusIdle;
    [self.lock unlock];
    
    if (!resultPtr) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeDownloadFailed, @"Download returned no result");
        }
        return nil;
    }
    
    NSString *jsonString = [NSString stringWithUTF8String:resultPtr];
    m3u8dl_free_string(resultPtr);
    
    M3U8DownloadResult *result = [M3U8DownloadResult parseFromJSONString:jsonString];
    if (!result) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeJSONError, @"Failed to parse JSON response");
        }
        return nil;
    }
    
    if (!result.success) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeDownloadFailed, result.errorMessage ?: @"Unknown error");
        }
        return nil;
    }
    
    return result;
}

- (void)downloadURL:(NSString *)url
             toPath:(NSString *)outputPath
            options:(M3U8DownloadOptions *)options
           progress:(M3U8ProgressBlock)progressBlock
         completion:(M3U8DownloadCompletionBlock)completion {
    if (!completion) return;
    
    // 保存回调
    [self.lock lock];
    self.progressBlock = progressBlock;
    self.completionBlock = completion;
    [self.lock unlock];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        M3U8DownloadResult *result = [self downloadURL:url toPath:outputPath options:options error:&error];
        
        [self.lock lock];
        self.progressBlock = nil;
        M3U8DownloadCompletionBlock savedCompletion = self.completionBlock;
        self.completionBlock = nil;
        [self.lock unlock];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (savedCompletion) {
                savedCompletion(result, error);
            }
        });
    });
}

#pragma mark - 控制方法

- (void)cancel {
    [self.lock lock];
    BOOL disposed = self.isDisposed;
    [self.lock unlock];
    
    if (disposed) return;
    
    m3u8dl_cancel(self.instanceId);
    
    [self.lock lock];
    self.currentStatus = M3U8DownloadStatusCancelled;
    [self.lock unlock];
}

- (void)dispose {
    [self.lock lock];
    if (self.isDisposed) {
        [self.lock unlock];
        return;
    }
    self.isDisposed = YES;
    m3u8dl_instance_t instanceId = self.instanceId;
    [self.lock unlock];
    
    [[self class] unregisterInstance:instanceId];
    m3u8dl_dispose(instanceId);
}

#pragma mark - 回调设置

- (void)setLogHandler:(M3U8LogBlock)logBlock {
    [self.lock lock];
    self.logBlock = logBlock;
    [self.lock unlock];
}

#pragma mark - 功能查询

- (BOOL)isFeatureSupported:(NSString *)feature {
    [self.lock lock];
    BOOL disposed = self.isDisposed;
    [self.lock unlock];
    
    if (disposed || !feature) return NO;
    
    return m3u8dl_is_feature_supported(self.instanceId, [feature UTF8String]) != 0;
}

- (NSArray<NSString *> *)getProcessors:(NSError **)error {
    if (![self checkDisposed:error]) return nil;
    
    char *resultPtr = m3u8dl_get_processors(self.instanceId);
    if (!resultPtr) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeInternalError, @"Failed to get processors");
        }
        return nil;
    }
    
    NSString *jsonString = [NSString stringWithUTF8String:resultPtr];
    m3u8dl_free_string(resultPtr);
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeJSONError, @"Invalid JSON encoding");
        }
        return nil;
    }
    
    NSError *jsonError = nil;
    NSArray *processors = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError || ![processors isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeJSONError, @"Failed to parse processors JSON");
        }
        return nil;
    }
    
    return processors;
}

#pragma mark - 私有方法

- (BOOL)checkDisposed:(NSError **)error {
    [self.lock lock];
    BOOL disposed = self.isDisposed;
    [self.lock unlock];
    
    if (disposed) {
        if (error) {
            *error = M3U8ErrorMake(M3U8ErrorCodeDisposed, @"Downloader has been disposed");
        }
        return NO;
    }
    return YES;
}

- (void)handleProgress:(M3U8DownloadProgress *)progress {
    [self.lock lock];
    self.currentStatus = progress.status;
    M3U8ProgressBlock block = self.progressBlock;
    id<M3U8DownloaderDelegate> delegate = self.delegate;
    [self.lock unlock];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block(progress);
        }
        if ([delegate respondsToSelector:@selector(downloader:didUpdateProgress:)]) {
            [delegate downloader:self didUpdateProgress:progress];
        }
    });
}

- (void)handleCompletion:(M3U8DownloadResult *)result {
    [self.lock lock];
    self.currentStatus = result.success ? M3U8DownloadStatusCompleted : M3U8DownloadStatusFailed;
    id<M3U8DownloaderDelegate> delegate = self.delegate;
    [self.lock unlock];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([delegate respondsToSelector:@selector(downloader:didFinishWithResult:)]) {
            [delegate downloader:self didFinishWithResult:result];
        }
    });
}

- (void)handleLog:(M3U8LogLevel)level message:(NSString *)message {
    [self.lock lock];
    M3U8LogBlock block = self.logBlock;
    id<M3U8DownloaderDelegate> delegate = self.delegate;
    [self.lock unlock];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block(level, message);
        }
        if ([delegate respondsToSelector:@selector(downloader:didLogWithLevel:message:)]) {
            [delegate downloader:self didLogWithLevel:level message:message];
        }
    });
}

@end
