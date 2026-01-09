//
//  M3U8MergeRequest.h
//  M3U8DownloaderKit
//
//  视频合并请求
//

#import <Foundation/Foundation.h>

@class M3U8MergeOptions;
@class M3U8CancellationToken;

NS_ASSUME_NONNULL_BEGIN

/**
 * 视频合并请求
 * 
 * 包含视频合并操作所需的所有输入参数。
 */
@interface M3U8MergeRequest : NSObject

/**
 * 输入文件URL数组
 * 按顺序合并这些文件
 */
@property (nonatomic, strong) NSArray<NSURL *> *inputFiles;

/**
 * 输出文件URL
 */
@property (nonatomic, strong) NSURL *outputURL;

/**
 * 合并选项
 * 如果为nil，使用默认选项
 */
@property (nonatomic, strong, nullable) M3U8MergeOptions *options;

/**
 * 进度回调
 * 参数：progress (0.0 - 1.0)
 * 在主线程调用
 */
@property (nonatomic, copy, nullable) void (^progressHandler)(double progress);

/**
 * 取消令牌
 * 用于取消操作
 */
@property (nonatomic, strong, nullable) M3U8CancellationToken *cancellationToken;

/**
 * 创建请求
 */
+ (instancetype)requestWithInputFiles:(NSArray<NSURL *> *)inputFiles
                            outputURL:(NSURL *)outputURL
                              options:(nullable M3U8MergeOptions *)options;

/**
 * 验证请求参数
 * @param error 如果验证失败，返回错误信息
 * @return 是否有效
 */
- (BOOL)validateWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
