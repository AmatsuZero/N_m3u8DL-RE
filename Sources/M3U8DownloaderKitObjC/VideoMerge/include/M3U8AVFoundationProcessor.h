//
//  M3U8AVFoundationProcessor.h
//  M3U8DownloaderKit
//
//  基于AVFoundation的视频处理器
//  使用系统原生框架进行视频合并，支持iOS和macOS
//

#import <Foundation/Foundation.h>
#if __has_include(<M3U8DownloaderKit/M3U8VideoProcessor.h>)
#import <M3U8DownloaderKit/M3U8VideoProcessor.h>
#else
#import "M3U8VideoProcessor.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * AVFoundation视频处理器
 * 
 * 使用AVFoundation框架进行视频合并。
 * 特点：
 * - 零依赖，使用系统框架
 * - 硬件加速支持
 * - 支持多种视频格式
 * - 支持分批处理大量文件
 * - iOS和macOS共享核心代码
 * 
 * 优先级：100
 */
@interface M3U8AVFoundationProcessor : NSObject <M3U8VideoProcessor>

/**
 * 创建处理器实例
 */
+ (instancetype)processor;

@end

NS_ASSUME_NONNULL_END
