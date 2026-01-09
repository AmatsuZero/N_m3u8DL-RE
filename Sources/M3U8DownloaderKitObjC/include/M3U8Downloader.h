//
//  M3U8Downloader.h
//  M3U8DownloaderKit
//
//  主下载器类 - Objective-C 封装层
//

#import <Foundation/Foundation.h>
#import "M3U8Types.h"
#import "M3U8Error.h"

NS_ASSUME_NONNULL_BEGIN

@class M3U8Downloader;

#pragma mark - 回调 Block 定义

/// 进度回调
typedef void (^M3U8ProgressBlock)(M3U8DownloadProgress *progress);

/// 完成回调
typedef void (^M3U8CompletionBlock)(M3U8DownloadResult *result);

/// 日志回调
typedef void (^M3U8LogBlock)(M3U8LogLevel level, NSString *message);

/// 解析完成回调
typedef void (^M3U8ParseCompletionBlock)(M3U8ParseResult * _Nullable result, NSError * _Nullable error);

/// 下载完成回调
typedef void (^M3U8DownloadCompletionBlock)(M3U8DownloadResult * _Nullable result, NSError * _Nullable error);

#pragma mark - M3U8Downloader 委托协议

/// M3U8Downloader 委托协议
@protocol M3U8DownloaderDelegate <NSObject>

@optional

/// 下载进度更新
/// @param downloader 下载器实例
/// @param progress 当前进度
- (void)downloader:(M3U8Downloader *)downloader didUpdateProgress:(M3U8DownloadProgress *)progress;

/// 下载完成
/// @param downloader 下载器实例
/// @param result 下载结果
- (void)downloader:(M3U8Downloader *)downloader didFinishWithResult:(M3U8DownloadResult *)result;

/// 日志输出
/// @param downloader 下载器实例
/// @param level 日志级别
/// @param message 日志消息
- (void)downloader:(M3U8Downloader *)downloader didLogWithLevel:(M3U8LogLevel)level message:(NSString *)message;

@end

#pragma mark - M3U8Downloader 类

/// M3U8/HLS/DASH 流媒体下载器
///
/// 这是一个线程安全的下载器类，提供同步和异步 API 用于解析和下载流媒体内容。
///
/// @code
/// M3U8Downloader *downloader = [[M3U8Downloader alloc] initWithConfiguration:nil error:nil];
///
/// // 异步解析流信息
/// [downloader parseURL:@"https://example.com/playlist.m3u8"
///           completion:^(M3U8ParseResult *result, NSError *error) {
///     if (result.success) {
///         NSLog(@"找到 %lu 个流", (unsigned long)result.streams.count);
///     }
/// }];
///
/// // 异步下载
/// [downloader downloadURL:@"https://example.com/playlist.m3u8"
///              toPath:@"/path/to/output.mp4"
///             options:nil
///            progress:^(M3U8DownloadProgress *progress) {
///     NSLog(@"进度: %ld%%", (long)progress.percentage);
/// }
///          completion:^(M3U8DownloadResult *result, NSError *error) {
///     if (result.success) {
///         NSLog(@"下载完成: %@", result.outputFile);
///     }
/// }];
/// @endcode
@interface M3U8Downloader : NSObject<NSProgressReporting>

#pragma mark - 属性

/// 委托
@property (nonatomic, weak, nullable) id<M3U8DownloaderDelegate> delegate;

/// 是否已释放
@property (nonatomic, readonly) BOOL isDisposed;

/// 当前下载状态
@property (nonatomic, readonly) M3U8DownloadStatus currentStatus;

#pragma mark - 初始化

/// 使用默认配置初始化
/// @param error 错误信息（如果初始化失败）
/// @return 下载器实例，失败返回 nil
- (nullable instancetype)initWithError:(NSError **)error;

/// 使用指定配置初始化
/// @param configuration 下载器配置（传入 nil 使用默认配置）
/// @param error 错误信息（如果初始化失败）
/// @return 下载器实例，失败返回 nil
- (nullable instancetype)initWithConfiguration:(nullable M3U8Configuration *)configuration
                                         error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// 不可用的初始化方法
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark - 解析方法

/// 同步解析 M3U8/DASH URL
/// @param url 流媒体 URL
/// @param error 错误信息
/// @return 解析结果，失败返回 nil
- (nullable M3U8ParseResult *)parseURL:(NSString *)url
                                 error:(NSError **)error;

/// 异步解析 M3U8/DASH URL
/// @param url 流媒体 URL
/// @param completion 完成回调（在主线程调用）
- (void)parseURL:(NSString *)url
      completion:(M3U8ParseCompletionBlock)completion;

#pragma mark - 下载方法

/// 同步下载
/// @param url 流媒体 URL
/// @param outputPath 输出文件路径
/// @param options 下载选项（可选）
/// @param error 错误信息
/// @return 下载结果，失败返回 nil
- (nullable M3U8DownloadResult *)downloadURL:(NSString *)url
                                      toPath:(NSString *)outputPath
                                     options:(nullable M3U8DownloadOptions *)options
                                       error:(NSError **)error;

/// 异步下载
/// @param url 流媒体 URL
/// @param outputPath 输出文件路径
/// @param options 下载选项（可选）
/// @param progressBlock 进度回调（可选，在主线程调用）
/// @param completion 完成回调（在主线程调用）
- (void)downloadURL:(NSString *)url
             toPath:(NSString *)outputPath
            options:(nullable M3U8DownloadOptions *)options
           progress:(nullable M3U8ProgressBlock)progressBlock
         completion:(M3U8DownloadCompletionBlock)completion;

#pragma mark - 控制方法

/// 取消当前下载
- (void)cancel;

/// 释放资源
- (void)dispose;

#pragma mark - 回调设置

/// 设置日志回调
/// @param logBlock 日志回调 Block
- (void)setLogHandler:(nullable M3U8LogBlock)logBlock;

#pragma mark - 功能查询

/// 检查功能是否支持
/// @param feature 功能名称（如 "hls", "dash", "decrypt"）
/// @return 是否支持
- (BOOL)isFeatureSupported:(NSString *)feature;

/// 获取可用的视频处理器列表
/// @param error 错误信息
/// @return 处理器名称数组，失败返回 nil
- (nullable NSArray<NSString *> *)getProcessors:(NSError **)error;

#pragma mark - 类方法

/// 获取库版本信息
/// @return 版本信息
+ (nullable M3U8VersionInfo *)versionInfo;

/// 释放所有下载器实例
+ (void)disposeAll;

@end

NS_ASSUME_NONNULL_END
