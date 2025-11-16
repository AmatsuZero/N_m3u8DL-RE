//
//  M3U8Downloader.h
//  N_m3u8DL-RE iOS Example
//
//  Objective-C wrapper for N_m3u8DL_RE_Core library
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 下载进度回调
typedef void (^M3U8DownloadProgressBlock)(int progress, long long downloadedBytes, long long totalBytes);

/// 下载完成回调
typedef void (^M3U8DownloadCompletionBlock)(BOOL success, NSString * _Nullable outputPath, NSError * _Nullable error);

/// M3U8 下载器
@interface M3U8Downloader : NSObject

/// 单例实例
+ (instancetype)sharedDownloader;

/// 初始化（自动调用）
- (instancetype)init;

/// 开始下载
/// @param url M3U8 播放列表 URL
/// @param outputPath 输出文件路径
/// @param progressBlock 进度回调（可选）
/// @param completionBlock 完成回调
- (void)downloadURL:(NSString *)url
         outputPath:(NSString *)outputPath
         onProgress:(nullable M3U8DownloadProgressBlock)progressBlock
       onCompletion:(M3U8DownloadCompletionBlock)completionBlock;

/// 取消当前下载
- (void)cancel;

/// 获取当前下载进度 (0-100)
- (int)currentProgress;

/// 获取库版本
- (NSString *)libraryVersion;

/// 获取 API 版本
- (NSString *)apiVersion;

@end

NS_ASSUME_NONNULL_END
