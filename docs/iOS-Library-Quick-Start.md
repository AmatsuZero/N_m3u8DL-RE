# iOS Library 快速开始指南

## 🎯 目标

将 N_m3u8DL-RE 构建为 iOS Library，供 iOS/macOS 应用使用。

## ✅ 已完成

我们创建了一个**独立的 iOS Library 项目**，解决了原有的循环依赖问题。

## 🚀 立即开始

### 步骤 1: 构建库

```bash
# 1. 给脚本添加执行权限
chmod +x build-ios-library-full.sh

# 2. 构建 iOS Library
./build-ios-library-full.sh
```

### 步骤 2: 查看输出

```bash
# 查看生成的文件
ls -lh output/ios-library-full/ios-arm64/

# 应该看到：
# N_m3u8DL-RE.iOS.dylib  - 动态库文件
```

### 步骤 3: 测试库

```bash
# 检查库文件
file output/ios-library-full/ios-arm64/N_m3u8DL-RE.iOS.dylib

# 检查导出的符号
nm -g output/ios-library-full/ios-arm64/N_m3u8DL-RE.iOS.dylib | grep m3u8dl_ios
```

## 📖 使用示例

### Swift 示例

```swift
import Foundation

// 1. 初始化
m3u8dl_ios_init()

// 2. 设置进度回调
let callback: @convention(c) (Int32, Int64, Int64, Int64) -> Void = { 
    percentage, downloaded, total, speed in
    print("Progress: \(percentage)%")
}
m3u8dl_ios_set_progress_callback(callback)

// 3. 开始下载
let url = "https://example.com/playlist.m3u8"
let output = "/path/to/output.mp4"
m3u8dl_ios_download_simple(url, output)

// 4. 监控进度
while m3u8dl_ios_get_status() < 4 {
    let progress = m3u8dl_ios_get_progress()
    print("Progress: \(progress)%")
    sleep(1)
}
```

## 📚 详细文档

- **[项目 README](../src/N_m3u8DL-RE.iOS/README.md)** - 完整的 API 文档和示例
- **[项目总结](iOS-Library-Project-Summary.md)** - 项目结构和技术细节
- **[集成指南](iOS-Library-Integration.md)** - 如何集成到 iOS 项目

## 🔍 项目结构

```
src/N_m3u8DL-RE.iOS/          # 独立的 iOS Library 项目
├── Config/                   # 配置类
├── Entity/                   # 实体类
├── Downloader/               # 下载器实现
├── PublicAPI/                # 公共 API
└── README.md                 # 项目文档
```

## ✨ 主要特点

- ✅ **独立项目** - 不依赖主项目，没有循环依赖
- ✅ **完整功能** - 包含解析和下载功能
- ✅ **易于使用** - 简化的 API 和配置
- ✅ **高性能** - NativeAOT 编译
- ✅ **跨语言** - C 风格接口，支持 Swift/Objective-C

## 🎓 API 概览

### 核心函数

```c
// 初始化
int m3u8dl_ios_init();

// 下载
int m3u8dl_ios_download_simple(const char* url, const char* output);

// 进度
int m3u8dl_ios_get_progress();
int m3u8dl_ios_get_status();

// 控制
int m3u8dl_ios_cancel();
```

## 💡 常见问题

### Q: 构建失败怎么办？

A: 检查以下几点：
1. 确保已安装本地 .NET SDK (`./setup-local-dotnet.sh`)
2. 确保已安装 iOS workload (`./.dotnet/dotnet workload install ios`)
3. 查看构建日志中的错误信息

### Q: 如何集成到 iOS 项目？

A: 参考 [src/N_m3u8DL-RE.iOS/README.md](../src/N_m3u8DL-RE.iOS/README.md) 中的集成指南。

### Q: 支持哪些平台？

A: 当前支持：
- ✅ iOS 设备 (arm64)
- 🔄 iOS 模拟器 (待添加)
- 🔄 macOS (待添加)

### Q: 与原来的 Core 项目有什么区别？

A: 
- **原 Core 项目**: 依赖主项目，有循环依赖，无法独立构建
- **新 iOS 项目**: 独立项目，无循环依赖，可以独立构建

## 🔧 故障排查

### 1. 检查 .NET SDK

```bash
./.dotnet/dotnet --version
```

### 2. 检查 iOS workload

```bash
./.dotnet/dotnet workload list
```

### 3. 重新构建

```bash
# 清理
rm -rf output/ios-library-full

# 重新构建
./build-ios-library-full.sh
```

## 📞 获取帮助

- 查看 [项目 README](../src/N_m3u8DL-RE.iOS/README.md)
- 查看 [问题分析文档](iOS-Library-Build-Issue.md)
- 查看 [项目总结](iOS-Library-Project-Summary.md)

## 🎉 下一步

1. ✅ 构建库文件
2. ✅ 测试基本功能
3. 📝 集成到你的 iOS 项目
4. 🚀 开始使用！

---

**更新时间**: 2025-11-16  
**版本**: 1.0.0
