//
//  M3U8MergeResult.h
//  M3U8DownloaderKit
//
//  视频合并结果
//

#import <Foundation/Foundation.h>

@class M3U8MergeStatistics;

NS_ASSUME_NONNULL_BEGIN

/**
 * 视频合并结果
 * 
 * 包含视频合并操作的结果信息。
 */
@interface M3U8MergeResult : NSObject

/**
 * 是否成功
 */
@property (nonatomic, assign) BOOL success;

/**
 * 输出文件URL
 * 如果成功，此属性包含输出文件的路径
 */
@property (nonatomic, strong, nullable) NSURL *outputURL;

/**
 * 输出视频时长（秒）
 */
@property (nonatomic, assign) NSTimeInterval duration;

/**
 * 使用的处理器名称
 */
@property (nonatomic, copy) NSString *processorName;

/**
 * 错误信息
 * 如果失败，此属性包含错误详情
 */
@property (nonatomic, strong, nullable) NSError *error;

/**
 * 统计信息
 */
@property (nonatomic, strong) M3U8MergeStatistics *statistics;

/**
 * 是否被取消
 */
@property (nonatomic, assign) BOOL cancelled;

/**
 * 创建成功结果
 */
+ (instancetype)successWithOutputURL:(NSURL *)outputURL
                            duration:(NSTimeInterval)duration
                       processorName:(NSString *)processorName
                          statistics:(M3U8MergeStatistics *)statistics;

/**
 * 创建失败结果
 */
+ (instancetype)failureWithError:(NSError *)error
                   processorName:(NSString *)processorName
                      statistics:(nullable M3U8MergeStatistics *)statistics;

/**
 * 创建取消结果
 */
+ (instancetype)cancelledWithProcessorName:(NSString *)processorName
                                statistics:(nullable M3U8MergeStatistics *)statistics;

@end

NS_ASSUME_NONNULL_END
