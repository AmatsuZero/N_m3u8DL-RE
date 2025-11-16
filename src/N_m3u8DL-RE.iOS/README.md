# N_m3u8DL-RE.iOS - iOS Library 项目

这是一个独立的 iOS Library 项目，将 N_m3u8DL-RE 的核心功能打包为可供 iOS/macOS 应用使用的动态库。

## 📋 项目特点

- ✅ **独立项目**：不依赖主项目，可以独立构建
- ✅ **完整功能**：包含解析和下载功能
- ✅ **NativeAOT**：使用 NativeAOT 编译，性能优异
- ✅ **C 接口**：提供 C 风格的 API，易于跨语言调用
- ✅ **简化配置**：简化的配置类，易于使用

## 🏗️ 项目结构

```
src/N_m3u8DL-RE.iOS/
├── Config/
│   └── iOSDownloaderConfig.cs      # 下载器配置
├── Entity/
│   └── DownloadEntities.cs         # 实体类（进度、结果等）
├── Downloader/
│   ├── IiOSDownloader.cs           # 下载器接口
│   └── iOSDownloader.cs            # 下载器实现
├── PublicAPI/
│   └── iOSNativeAPI.cs             # 公共 API（C 接口）
└── N_m3u8DL-RE.iOS.csproj          # 项目配置
```

## 🚀 快速开始

### 1. 构建库

```bash
# 给脚本添加执行权限
chmod +x build-ios-library-full.sh

# 构建 iOS Library
./build-ios-library-full.sh
```

### 2. 输出文件

构建完成后，在 `output/ios-library-full/` 目录下会生成：

```
output/ios-library-full/
└── ios-arm64/
    ├── N_m3u8DL-RE.iOS.dylib    # 动态库
    └── N_m3u8DL-RE.iOS.h        # 头文件（如果生成）
```

### 3. 集成到 iOS 项目

查看详细的集成指南：[docs/iOS-Library-Integration.md](../../docs/iOS-Library-Integration.md)

## 📖 API 文档

### 初始化

```c
// 初始化库
int m3u8dl_ios_init();
```

### 设置回调

```c
// 进度回调函数类型
typedef void (*ProgressCallback)(int percentage, long downloadedBytes, long totalBytes, long speed);

// 设置进度回调
void m3u8dl_ios_set_progress_callback(ProgressCallback callback);
```

### 下载

```c
// 简单下载（推荐）
int m3u8dl_ios_download_simple(const char* url, const char* outputPath);

// 高级下载（使用 JSON 配置）
int m3u8dl_ios_download(const char* configJson);
```

### 获取状态

```c
// 获取进度百分比 (0-100)
int m3u8dl_ios_get_progress();

// 获取已下载字节数
long m3u8dl_ios_get_downloaded_bytes();

// 获取总字节数
long m3u8dl_ios_get_total_bytes();

// 获取下载速度 (字节/秒)
long m3u8dl_ios_get_speed();

// 获取下载状态
// 0=未开始, 1=初始化, 2=下载中, 3=合并中, 4=完成, 5=取消, 6=失败
int m3u8dl_ios_get_status();
```

### 控制

```c
// 取消下载
int m3u8dl_ios_cancel();
```

### 版本信息

```c
// 获取版本字符串
const char* m3u8dl_ios_get_version();

// 获取 API 版本号
int m3u8dl_ios_get_api_version();

// 释放字符串内存
void m3u8dl_ios_free_string(char* ptr);
```

## 💡 使用示例

### Swift 示例

```swift
import Foundation

// 1. 初始化
m3u8dl_ios_init()

// 2. 设置进度回调
let callback: @convention(c) (Int32, Int64, Int64, Int64) -> Void = { percentage, downloaded, total, speed in
    print("Progress: \(percentage)%, Downloaded: \(downloaded), Speed: \(speed) bytes/s")
}
m3u8dl_ios_set_progress_callback(callback)

// 3. 开始下载
let url = "https://example.com/playlist.m3u8"
let output = "/path/to/output.mp4"
let result = m3u8dl_ios_download_simple(url, output)

if result == 0 {
    print("Download started successfully")
} else {
    print("Failed to start download: \(result)")
}

// 4. 监控进度
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    let progress = m3u8dl_ios_get_progress()
    let status = m3u8dl_ios_get_status()
    print("Progress: \(progress)%, Status: \(status)")
    
    if status == 4 { // Completed
        print("Download completed!")
    }
}

// 5. 取消下载（如需要）
// m3u8dl_ios_cancel()
```

### Objective-C 示例

```objc
#import <Foundation/Foundation.h>

// 进度回调
void progressCallback(int percentage, long downloadedBytes, long totalBytes, long speed) {
    NSLog(@"Progress: %d%%, Downloaded: %ld, Speed: %ld bytes/s", 
          percentage, downloadedBytes, speed);
}

int main() {
    // 1. 初始化
    m3u8dl_ios_init();
    
    // 2. 设置回调
    m3u8dl_ios_set_progress_callback(progressCallback);
    
    // 3. 开始下载
    const char* url = "https://example.com/playlist.m3u8";
    const char* output = "/path/to/output.mp4";
    int result = m3u8dl_ios_download_simple(url, output);
    
    if (result == 0) {
        NSLog(@"Download started successfully");
    } else {
        NSLog(@"Failed to start download: %d", result);
    }
    
    // 4. 监控进度
    while (m3u8dl_ios_get_status() < 4) {
        int progress = m3u8dl_ios_get_progress();
        NSLog(@"Progress: %d%%", progress);
        sleep(1);
    }
    
    NSLog(@"Download completed!");
    return 0;
}
```

### JSON 配置示例

```json
{
  "Url": "https://example.com/playlist.m3u8",
  "OutputPath": "/path/to/output.mp4",
  "MaxThreads": 8,
  "MaxSpeed": 0,
  "RetryCount": 3,
  "TimeoutSeconds": 30,
  "Headers": {
    "User-Agent": "Mozilla/5.0",
    "Referer": "https://example.com"
  },
  "AutoMerge": true,
  "DeleteTempFiles": true,
  "LogLevel": 3
}
```

## 🔧 配置选项

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `Url` | string | 必填 | 下载 URL |
| `OutputPath` | string | 必填 | 输出路径 |
| `MaxThreads` | int | 8 | 最大并发数 |
| `MaxSpeed` | long | 0 | 速度限制（字节/秒），0=不限制 |
| `RetryCount` | int | 3 | 重试次数 |
| `TimeoutSeconds` | int | 30 | 超时时间（秒） |
| `Headers` | dict | {} | 自定义请求头 |
| `AutoMerge` | bool | true | 是否自动合并 |
| `DeleteTempFiles` | bool | true | 是否删除临时文件 |
| `ProxyUrl` | string | null | 代理地址 |
| `UserAgent` | string | null | User-Agent |
| `Referer` | string | null | Referer |
| `Cookie` | string | null | Cookie |
| `SkipCertificateValidation` | bool | false | 跳过证书验证 |
| `LogLevel` | int | 3 | 日志级别 (0-4) |

## 📊 状态码

### 下载状态

| 状态码 | 名称 | 说明 |
|--------|------|------|
| 0 | NotStarted | 未开始 |
| 1 | Initializing | 初始化中 |
| 2 | Downloading | 下载中 |
| 3 | Merging | 合并中 |
| 4 | Completed | 已完成 |
| 5 | Cancelled | 已取消 |
| 6 | Failed | 失败 |

### 错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| -1 | 配置无效 |
| -2 | 未找到流 |
| -3 | 未找到分片 |
| -4 | 已取消 |
| -99 | 未知错误 |

## 🔍 故障排查

### 构建失败

1. **检查 .NET SDK**
   ```bash
   ./.dotnet/dotnet --version
   ```

2. **检查 iOS workload**
   ```bash
   ./.dotnet/dotnet workload list
   ```

3. **重新安装 workload**
   ```bash
   ./.dotnet/dotnet workload install ios
   ```

### 运行时错误

1. **检查库文件**
   ```bash
   file output/ios-library-full/ios-arm64/*.dylib
   ```

2. **检查符号导出**
   ```bash
   nm -g output/ios-library-full/ios-arm64/*.dylib | grep m3u8dl_ios
   ```

## 📚 相关文档

- [iOS Library 构建问题分析](../../docs/iOS-Library-Build-Issue.md)
- [iOS Library 集成指南](../../docs/iOS-Library-Integration.md)
- [本地 .NET 安装指南](../../docs/Local-Dotnet-Installation.md)
- [项目重构文档](../../REFACTORING.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

与主项目相同

---

**版本**: 0.5.1-ios  
**更新时间**: 2025-11-16
