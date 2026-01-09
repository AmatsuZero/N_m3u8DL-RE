//
//  M3U8VideoProcessorRegistry.h
//  M3U8DownloaderKit
//
//  视频处理器注册表
//  管理所有视频处理器的注册、查询和选择
//

#import <Foundation/Foundation.h>

@protocol M3U8VideoProcessor;

NS_ASSUME_NONNULL_BEGIN

/**
 * 视频处理器注册表
 * 
 * 单例类，负责管理所有视频处理器的注册和查询。
 * 支持：
 * - 处理器注册
 * - 按优先级自动选择处理器
 * - 按名称查询处理器
 * - 按功能查询处理器
 * - 线程安全操作
 */
@interface M3U8VideoProcessorRegistry : NSObject

/**
 * 获取单例实例
 */
+ (instancetype)sharedRegistry;

/**
 * 注册视频处理器
 * 
 * 注册后的处理器会按优先级排序。
 * 如果已存在同名处理器，会被替换。
 * 
 * @param processor 要注册的处理器
 */
- (void)registerProcessor:(id<M3U8VideoProcessor>)processor;

/**
 * 注销视频处理器
 * 
 * @param processorName 处理器名称
 */
- (void)unregisterProcessorWithName:(NSString *)processorName;

/**
 * 获取所有可用的处理器
 * 
 * 异步检查所有已注册处理器的可用性，返回可用的处理器列表。
 * 结果按优先级降序排序。
 * 
 * @param completion 完成回调，返回可用的处理器数组
 */
- (void)getAvailableProcessorsWithCompletion:(void (^)(NSArray<id<M3U8VideoProcessor>> *processors))completion;

/**
 * 按名称获取处理器
 * 
 * @param name 处理器名称
 * @return 处理器实例，如果不存在返回nil
 */
- (nullable id<M3U8VideoProcessor>)getProcessorByName:(NSString *)name;

/**
 * 按功能获取支持的处理器
 * 
 * 异步查询支持指定功能的所有可用处理器。
 * 
 * @param feature 功能名称
 * @param completion 完成回调，返回支持该功能的处理器数组
 */
- (void)getProcessorsByFeature:(NSString *)feature
                    completion:(void (^)(NSArray<id<M3U8VideoProcessor>> *processors))completion;

/**
 * 检查是否有处理器支持指定功能
 * 
 * @param feature 功能名称
 * @param completion 完成回调，返回是否支持
 */
- (void)isFeatureSupported:(NSString *)feature
                completion:(void (^)(BOOL supported))completion;

/**
 * 获取最佳处理器
 * 
 * 根据优先级和可用性自动选择最佳处理器。
 * 
 * @param completion 完成回调，返回最佳处理器，如果没有可用处理器返回nil
 */
- (void)getBestProcessorWithCompletion:(void (^)(id<M3U8VideoProcessor> _Nullable processor))completion;

/**
 * 获取所有已注册的处理器名称
 * 
 * @return 处理器名称数组
 */
- (NSArray<NSString *> *)getAllProcessorNames;

/**
 * 清空所有已注册的处理器
 */
- (void)clearAllProcessors;

@end

NS_ASSUME_NONNULL_END
