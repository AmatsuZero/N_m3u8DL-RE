#
#  M3U8DownloaderKit.podspec
#
#  M3U8/HLS/DASH 流媒体下载库的 Swift 包装层
#
#  使用方法:
#    pod 'M3U8DownloaderKit'
#
#  本地验证:
#    pod lib lint M3U8DownloaderKit.podspec --allow-warnings
#    pod spec lint M3U8DownloaderKit.podspec --allow-warnings --quick
#
#  支持平台:
#    - iOS 15.0+ (真机 + 模拟器)
#    - macOS 12.0+ (Apple Silicon + Intel)
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
    
    支持平台：iOS 15.0+、macOS 12.0+
  DESC
  
  spec.homepage     = "https://github.com/AmatsuZero/N_m3u8DL-RE"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "AmatsuZero" => "amatsuZero@jzh16s.com" }
  
  # 平台要求
  spec.ios.deployment_target = "15.0"
  spec.osx.deployment_target = "12.0"
  
  # Swift 版本
  spec.swift_versions = ["5.9", "5.10", "6.0"]
  
  # 源码位置
  # 注意：发布前需要先创建对应的 git tag
  spec.source       = {
    :git => "https://github.com/AmatsuZero/N_m3u8DL-RE.git",
    :tag => "v#{spec.version}"
  }
  
  # 源文件 - Swift 包装层代码 + C 桥接层头文件
  spec.source_files = [
    "Sources/M3U8DownloaderKit/**/*.swift",
    "Sources/M3U8DownloaderKit_C/include/**/*.h"
  ]
  
  # 排除测试用的 Mock 文件
  spec.exclude_files = [
    "Sources/M3U8DownloaderKit/MockImplementation.swift"
  ]
  
  # 公开头文件
  spec.public_header_files = "Sources/M3U8DownloaderKit_C/include/*.h"
  
  # XCFramework 依赖（包含所有平台架构）
  # 注意：XCFramework 中已包含 C 接口的头文件和实现
  spec.vendored_frameworks = "build/xcframework/M3U8DownloaderKit.xcframework"
  
  # 模块映射
  spec.preserve_paths = "Sources/M3U8DownloaderKit_C/include/module.modulemap"
  
  # 构建配置
  spec.pod_target_xcconfig = {
    # 定义 COCOAPODS 宏，用于条件编译
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "COCOAPODS",
    # 头文件搜索路径
    "HEADER_SEARCH_PATHS" => "$(PODS_TARGET_SRCROOT)/Sources/M3U8DownloaderKit_C/include",
    # 让 Swift 能够导入 C 头文件
    "SWIFT_INCLUDE_PATHS" => "$(PODS_TARGET_SRCROOT)/Sources/M3U8DownloaderKit_C/include",
    # 链接配置
    "OTHER_LDFLAGS" => "-ObjC"
  }
  
  # 用户构建配置
  spec.user_target_xcconfig = {
    # 无需排除架构，支持所有平台
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
