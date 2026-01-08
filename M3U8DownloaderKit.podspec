#
#  M3U8DownloaderKit.podspec
#
#  M3U8/HLS/DASH 流媒体下载库的 Swift 包装层
#
#  使用方法:
#    pod 'M3U8DownloaderKit'
#

Pod::Spec.new do |spec|
  spec.name         = "M3U8DownloaderKit"
  spec.version      = "1.0.0"
  spec.summary      = "M3U8/HLS/DASH streaming media downloader for iOS"
  
  spec.description  = <<-DESC
    M3U8DownloaderKit 是一个功能强大的流媒体下载库，
    支持 M3U8/HLS/DASH 协议，提供现代化的 Swift API，
    支持 async/await 异步操作，符合 Swift 6 并发模型。
    
    主要功能：
    - M3U8/HLS/DASH 流解析
    - 多质量流选择
    - 加密流解密支持
    - 实时下载进度监控
    - 分段下载和合并
  DESC
  
  spec.homepage     = "https://github.com/nilaoda/N_m3u8DL-RE"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "nilaoda" => "nilaoda@example.com" }
  
  # 平台要求
  spec.ios.deployment_target = "13.0"
  
  # Swift 版本
  spec.swift_versions = ["5.9", "5.10", "6.0"]
  
  # 源码位置
  spec.source       = {
    :git => "https://github.com/nilaoda/N_m3u8DL-RE.git",
    :tag => "v#{spec.version}"
  }
  
  # 源文件
  spec.source_files = [
    "swift/Sources/M3U8DownloaderKit/**/*.swift",
    "swift/Sources/M3U8DownloaderKit_C/**/*.{h,c}"
  ]
  
  # 公开头文件
  spec.public_header_files = "swift/Sources/M3U8DownloaderKit_C/include/*.h"
  
  # XCFramework 依赖
  spec.vendored_frameworks = "build/xcframework/M3U8DownloaderKit.xcframework"
  
  # 模块映射
  spec.preserve_paths = "swift/Sources/M3U8DownloaderKit_C/include/module.modulemap"
  spec.pod_target_xcconfig = {
    "SWIFT_INCLUDE_PATHS" => "$(PODS_TARGET_SRCROOT)/swift/Sources/M3U8DownloaderKit_C/include",
    "OTHER_LDFLAGS" => "-ObjC"
  }
  
  # 框架依赖
  spec.frameworks = "Foundation", "Security"
  
  # 系统库依赖
  spec.libraries = "z", "c++"
  
  # 要求 ARC
  spec.requires_arc = true
  
  # 静态框架
  spec.static_framework = false
end
