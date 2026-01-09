//
//  M3U8MergeStatistics.h
//  M3U8DownloaderKit
//
//  视频合并统计信息
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 视频合并统计信息
 * 
 * 包含视频合并操作的性能统计数据。
 */
@interface M3U8MergeStatistics : NSObject

/**
 * 总耗时（秒）
 */
@property (nonatomic, assign) NSTimeInterval totalDuration;

/**
 * 输入文件数量
 */
@property (nonatomic, assign) NSInteger inputFileCount;

/**
 * 输入文件总大小（字节）
 */
@property (nonatomic, assign) int64_t totalInputSize;

/**
 * 输出文件大小（字节）
 */
@property (nonatomic, assign) int64_t outputSize;

/**
 * 平均处理速度（MB/s）
 */
@property (nonatomic, assign) double averageSpeed;

/**
 * 峰值内存占用（字节）
 */
@property (nonatomic, assign) int64_t peakMemoryUsage;

/**
 * 批次数量
 * 如果使用了分批处理，此值表示总批次数
 */
@property (nonatomic, assign) NSInteger batchCount;

/**
 * 使用的处理器名称
 */
@property (nonatomic, copy) NSString *processorName;

/**
 * 是否使用了硬件加速
 */
@property (nonatomic, assign) BOOL hardwareAccelerated;

/**
 * 开始时间
 */
@property (nonatomic, strong) NSDate *startTime;

/**
 * 结束时间
 */
@property (nonatomic, strong, nullable) NSDate *endTime;

/**
 * 格式化的统计信息字符串
 */
- (NSString *)formattedDescription;

@end

NS_ASSUME_NONNULL_END
