//
//  M3U8MergeOptions.h
//  M3U8DownloaderKit
//
//  视频合并配置选项
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 输出格式枚举
 */
typedef NS_ENUM(NSInteger, M3U8OutputFormat) {
    M3U8OutputFormatMP4,        // MP4格式
    M3U8OutputFormatMOV,        // MOV格式
    M3U8OutputFormatM4V,        // M4V格式
    M3U8OutputFormatAuto        // 自动选择（根据输入格式）
};

/**
 * 缩放策略枚举
 */
typedef NS_ENUM(NSInteger, M3U8ScalingStrategy) {
    M3U8ScalingStrategyNone,            // 不缩放（如果分辨率不一致会失败）
    M3U8ScalingStrategyScaleToFirst,    // 缩放到第一个视频的分辨率
    M3U8ScalingStrategyScaleToMax,      // 缩放到最大分辨率
    M3U8ScalingStrategyScaleToMin,      // 缩放到最小分辨率
    M3U8ScalingStrategyAspectFit,       // 保持宽高比，适应目标尺寸
    M3U8ScalingStrategyAspectFill       // 保持宽高比，填充目标尺寸
};

/**
 * 视频合并配置选项
 * 
 * 包含视频合并操作的所有配置参数。
 */
@interface M3U8MergeOptions : NSObject

/**
 * 输出格式
 * 默认：M3U8OutputFormatMP4
 */
@property (nonatomic, assign) M3U8OutputFormat outputFormat;

/**
 * 视频编解码器
 * 例如："h264"、"hevc"
 * 默认：nil（使用输入视频的编解码器）
 */
@property (nonatomic, copy, nullable) NSString *videoCodec;

/**
 * 音频编解码器
 * 例如："aac"、"mp3"
 * 默认：nil（使用输入音频的编解码器）
 */
@property (nonatomic, copy, nullable) NSString *audioCodec;

/**
 * 是否使用AAC过滤器
 * 对于某些TS流，需要使用aac_adtstoasc过滤器
 * 默认：YES
 */
@property (nonatomic, assign) BOOL useAACFilter;

/**
 * 是否写入元数据
 * 默认：YES
 */
@property (nonatomic, assign) BOOL writeMetadata;

/**
 * 元数据字典
 * 键值对，例如：@{@"title": @"My Video", @"artist": @"John Doe"}
 * 默认：nil
 */
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *metadata;

/**
 * 分批处理的批次大小
 * 当输入文件数量超过此值时，会启用分批处理
 * 默认：100（iOS）/ 200（macOS）
 */
@property (nonatomic, assign) NSInteger batchSize;

/**
 * 分辨率缩放策略
 * 当输入视频分辨率不一致时的处理策略
 * 默认：M3U8ScalingStrategyScaleToFirst
 */
@property (nonatomic, assign) M3U8ScalingStrategy scalingStrategy;

/**
 * 是否优化网络传输
 * 启用后会优化文件结构以支持流式播放
 * 默认：YES
 */
@property (nonatomic, assign) BOOL optimizeForNetworkUse;

/**
 * 导出预设
 * AVFoundation导出预设，例如：AVAssetExportPresetHighestQuality
 * 默认：nil（使用AVAssetExportPresetPassthrough）
 */
@property (nonatomic, copy, nullable) NSString *exportPreset;

/**
 * 最大重试次数
 * 当合并失败时的重试次数
 * 默认：3
 */
@property (nonatomic, assign) NSInteger maxRetryCount;

/**
 * 重试延迟（秒）
 * 重试之间的延迟时间
 * 默认：1.0
 */
@property (nonatomic, assign) NSTimeInterval retryDelay;

/**
 * 是否启用详细日志
 * 默认：NO
 */
@property (nonatomic, assign) BOOL verboseLogging;

/**
 * 创建默认配置
 */
+ (instancetype)defaultOptions;

@end

NS_ASSUME_NONNULL_END
