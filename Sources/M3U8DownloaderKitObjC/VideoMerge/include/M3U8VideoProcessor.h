//
//  M3U8VideoProcessor.h
//  M3U8DownloaderKit
//
//  视频处理器协议定义
//  定义了视频合并功能的核心接口
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 前向声明
@class M3U8MergeRequest;
@class M3U8MergeResult;

/**
 * 视频处理器协议
 * 
 * 所有视频处理器实现都必须遵循此协议。
 * 该协议定义了视频合并的核心接口，支持：
 * - 处理器可用性检测
 * - 视频片段合并
 * - 功能支持查询
 * - 优先级管理
 */
@protocol M3U8VideoProcessor <NSObject>

@required

/**
 * 处理器名称
 * 
 * 用于标识处理器类型，例如 "AVFoundation"、"FFmpeg"、"Basic"
 */
@property (nonatomic, readonly) NSString *name;

/**
 * 处理器优先级
 * 
 * 数值越大优先级越高。系统会按优先级降序选择处理器。
 * 建议值：
 * - AVFoundation: 100
 * - FFmpeg: 50
 * - Basic: 1
 */
@property (nonatomic, readonly) NSInteger priority;

/**
 * 检查处理器是否可用
 * 
 * 异步检查处理器是否可以在当前环境中使用。
 * 例如，检查必要的框架是否可用、依赖是否满足等。
 * 
 * @param completion 完成回调，返回是否可用
 */
- (void)isAvailableWithCompletion:(void (^)(BOOL available))completion;

/**
 * 合并视频片段
 * 
 * 执行视频合并操作。这是处理器的核心功能。
 * 
 * @param request 合并请求，包含输入文件、输出路径、配置选项等
 * @param completion 完成回调，返回合并结果或错误
 */
- (void)mergeWithRequest:(M3U8MergeRequest *)request
              completion:(void (^)(M3U8MergeResult * _Nullable result, NSError * _Nullable error))completion;

/**
 * 检查是否支持特定功能
 * 
 * 查询处理器是否支持某个特定功能。
 * 
 * @param feature 功能名称，例如 "hardware_acceleration"、"format_conversion"、"metadata_writing"
 * @return 是否支持该功能
 */
- (BOOL)supportsFeature:(NSString *)feature;

@end

/**
 * 常用功能名称常量
 */
FOUNDATION_EXPORT NSString * const M3U8VideoProcessorFeatureHardwareAcceleration;  // 硬件加速
FOUNDATION_EXPORT NSString * const M3U8VideoProcessorFeatureFormatConversion;      // 格式转换
FOUNDATION_EXPORT NSString * const M3U8VideoProcessorFeatureMetadataWriting;       // 元数据写入
FOUNDATION_EXPORT NSString * const M3U8VideoProcessorFeatureAudioMixing;           // 音频混流
FOUNDATION_EXPORT NSString * const M3U8VideoProcessorFeatureVideoComposition;      // 视频组合
FOUNDATION_EXPORT NSString * const M3U8VideoProcessorFeatureResolutionScaling;     // 分辨率缩放
FOUNDATION_EXPORT NSString * const M3U8VideoProcessorFeatureBatchProcessing;       // 分批处理
FOUNDATION_EXPORT NSString * const M3U8VideoProcessorFeatureCancellation;          // 取消操作

NS_ASSUME_NONNULL_END
