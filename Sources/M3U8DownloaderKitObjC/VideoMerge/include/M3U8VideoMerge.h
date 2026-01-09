//
//  M3U8VideoMerge.h
//  M3U8DownloaderKit
//
//  视频合并模块公共头文件
//  导入此文件即可使用所有视频合并功能
//

#import <Foundation/Foundation.h>

//! Project version number for M3U8VideoMerge.
FOUNDATION_EXPORT double M3U8VideoMergeVersionNumber;

//! Project version string for M3U8VideoMerge.
FOUNDATION_EXPORT const unsigned char M3U8VideoMergeVersionString[];

// 核心协议和接口
#import <M3U8DownloaderKitObjC/M3U8VideoProcessor.h>
#import <M3U8DownloaderKitObjC/M3U8CancellationToken.h>
#import <M3U8DownloaderKitObjC/M3U8MergeOptions.h>
#import <M3U8DownloaderKitObjC/M3U8MergeRequest.h>
#import <M3U8DownloaderKitObjC/M3U8MergeResult.h>
#import <M3U8DownloaderKitObjC/M3U8MergeStatistics.h>

// 处理器注册表
#import <M3U8DownloaderKitObjC/M3U8VideoProcessorRegistry.h>

// AVFoundation处理器
#import <M3U8DownloaderKitObjC/M3U8AVFoundationProcessor.h>
