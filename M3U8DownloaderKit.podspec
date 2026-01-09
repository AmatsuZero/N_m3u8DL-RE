#
#  M3U8DownloaderKit.podspec
#
#  M3U8/HLS/DASH 流媒体下载库 - Objective-C 封装层
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
  spec.summary      = "M3U8/HLS/DASH streaming media downloader for iOS and macOS"
  
  spec.description  = <<-DESC
    M3U8DownloaderKit 是一个功能强大的流媒体下载库，
    支持 M3U8/HLS/DASH 协议，提供现代化的 Objective-C API。
    
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
  
  # 源码位置
  # 注意：发布前需要先创建对应的 git tag
  spec.source       = {
    :git => "https://github.com/AmatsuZero/N_m3u8DL-RE.git",
    :tag => "v#{spec.version}"
  }
  
  # XCFramework 依赖（包含 .NET NativeAOT 编译的核心库）
  # 注意：内部 Framework 名称为 M3U8Core，避免与 Pod 库名称冲突
  spec.vendored_frameworks = "build/xcframework/M3U8Core.xcframework"
  
  # Objective-C 源文件
  spec.source_files = "Sources/M3U8DownloaderKitObjC/**/*.{h,m}"
  
  # 公开头文件
  spec.public_header_files = "Sources/M3U8DownloaderKitObjC/include/*.h"
  
  # 框架依赖
  spec.frameworks = "Foundation", "Security"
  
  # 系统库依赖
  spec.libraries = "z", "c++"
  
  # 要求 ARC
  spec.requires_arc = true
  
  # 动态框架
  spec.static_framework = false
  
  # 构建配置
  spec.pod_target_xcconfig = {
    # 头文件搜索路径 - 让 ObjC 能找到 C 头文件（m3u8dl.h）
    "HEADER_SEARCH_PATHS" => [
      "$(PODS_TARGET_SRCROOT)/Sources/M3U8DownloaderKitObjC/include",
      "$(PODS_ROOT)/M3U8DownloaderKit/Sources/M3U8DownloaderKitObjC/include"
    ].join(" "),
    # Framework 搜索路径 - 找到 XCFramework
    "FRAMEWORK_SEARCH_PATHS" => "$(PODS_TARGET_SRCROOT)/build/xcframework",
    # 链接 XCFramework（M3U8Core）
    "OTHER_LDFLAGS" => "-ObjC -framework M3U8Core"
  }
  
  # 用户构建配置
  spec.user_target_xcconfig = {
    # 确保用户项目能找到 XCFramework
    "FRAMEWORK_SEARCH_PATHS" => "$(PODS_ROOT)/M3U8DownloaderKit/build/xcframework"
  }
end
