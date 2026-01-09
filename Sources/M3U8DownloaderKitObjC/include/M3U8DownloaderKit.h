//
//  M3U8DownloaderKit.h
//  M3U8DownloaderKit
//
//  Objective-C 封装层 - M3U8/HLS/DASH 流媒体下载库
//
//  使用方法:
//    #import <M3U8DownloaderKit/M3U8DownloaderKit.h>
//
//  支持平台:
//    - iOS 15.0+
//    - macOS 12.0+
//

#import <Foundation/Foundation.h>

//! Project version number for M3U8DownloaderKit.
FOUNDATION_EXPORT double M3U8DownloaderKitVersionNumber;

//! Project version string for M3U8DownloaderKit.
FOUNDATION_EXPORT const unsigned char M3U8DownloaderKitVersionString[];

// 导入所有公开头文件
#if __has_include(<M3U8DownloaderKit/M3U8Downloader.h>)
#import <M3U8DownloaderKit/M3U8Downloader.h>
#else
#import "M3U8Downloader.h"
#endif
#if __has_include(<M3U8DownloaderKit/M3U8Types.h>)
#import <M3U8DownloaderKit/M3U8Types.h>
#else
#import "M3U8Types.h"
#endif
#if __has_include(<M3U8DownloaderKit/M3U8Error.h>)
#import <M3U8DownloaderKit/M3U8Error.h>
#else
#import "M3U8Error.h"
#endif

// C语言接口
#if __has_include(<M3U8DownloaderKit/m3u8dl.h>)
#import <M3U8DownloaderKit/m3u8dl.h>
#else
#import "m3u8dl.h"
#endif