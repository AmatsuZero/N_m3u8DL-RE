# M3U8DownloaderKit

M3U8/HLS/DASH 流媒体下载库的 Swift 包装层，提供现代化的 Swift API。

## 特性

- ✅ **现代 Swift API**: 使用 async/await 异步操作
- ✅ **Swift 6 并发安全**: 符合 Sendable 协议，线程安全
- ✅ **多协议支持**: M3U8/HLS/DASH 流媒体协议
- ✅ **加密流支持**: 支持 AES-128 等加密流解密
- ✅ **实时进度**: 支持进度回调和 AsyncStream
- ✅ **灵活集成**: 支持 CocoaPods 和 Swift Package Manager

## 系统要求

- iOS 15.0+
- macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## 安装

### Swift Package Manager

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/nilaoda/N_m3u8DL-RE.git", from: "1.0.0")
]
```

然后在 target 中添加：

```swift
.target(
    name: "YourTarget",
    dependencies: ["M3U8DownloaderKit"]
)
```

### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'M3U8DownloaderKit'
```

然后运行：

```bash
pod install
```

### 手动集成

1. 将 `M3U8DownloaderKit.xcframework` 拖入项目
2. 在 "General" > "Frameworks, Libraries" 中设置为 "Embed & Sign"
3. 将 Swift 源文件添加到项目中

## 快速开始

### 基本用法

```swift
import M3U8DownloaderKit

// 创建下载器
let downloader = try M3U8Downloader()

// 解析流信息
let result = try await downloader.parse(url: "https://example.com/playlist.m3u8")
for stream in result.streams {
    print("流: \(stream.type) - \(stream.resolution ?? "N/A")")
}

// 下载
let downloadResult = try await downloader.download(
    url: "https://example.com/playlist.m3u8",
    to: "/path/to/output.mp4"
)

print("下载完成: \(downloadResult.formattedFileSize)")

// 释放资源
downloader.dispose()
```

### 链式 API

```swift
let result = try await M3U8Downloader.download("https://example.com/playlist.m3u8")
    .to("/path/to/output.mp4")
    .withHeaders(["User-Agent": "MyApp/1.0"])
    .autoSelectBestQuality()
    .start()
```

### 进度监控

```swift
let downloader = try M3U8Downloader()

// 方式 1: 回调
downloader.onProgress { progress in
    print("进度: \(progress.formattedProgress)")
    print("速度: \(progress.formattedSpeed)")
}

// 方式 2: AsyncStream
Task {
    for await progress in downloader.progressStream {
        print("下载进度: \(progress.percentage)%")
    }
}

try await downloader.download(url: url, to: outputPath)
```

### 自定义配置

```swift
let config = Configuration(
    maxConcurrency: 16,        // 最大并发数
    timeoutSeconds: 60,        // 超时时间
    retryCount: 5,             // 重试次数
    autoCleanup: true,         // 自动清理临时文件
    customHeaders: [           // 自定义请求头
        "User-Agent": "MyApp/1.0",
        "Authorization": "Bearer token"
    ]
)

let downloader = try M3U8Downloader(configuration: config)
```

### 下载选项

```swift
let options = DownloadOptions(
    decryptionKeys: ["kid:key"],           // 解密密钥
    customHeaders: ["Referer": "https://example.com"],
    autoSelectBestQuality: true,           // 自动选择最佳质量
    selectedStreamIds: ["video-1", "audio-1"]  // 或手动选择流
)

let result = try await downloader.download(
    url: url,
    to: outputPath,
    options: options
)
```

### 日志监控

```swift
downloader.onLog { level, message in
    switch level {
    case .debug:
        print("🔍 \(message)")
    case .info:
        print("ℹ️ \(message)")
    case .warning:
        print("⚠️ \(message)")
    case .error:
        print("❌ \(message)")
    }
}
```

### 功能查询

```swift
// 检查功能支持
if downloader.isFeatureSupported(.hls) {
    print("支持 HLS")
}

if downloader.isFeatureSupported(.dash) {
    print("支持 DASH")
}

// 获取版本信息
if let version = M3U8Downloader.getVersion() {
    print("版本: \(version.version)")
    print("平台: \(version.platform)")
}
```

### 取消下载

```swift
let task = try downloader.downloadAsync(url: url, to: outputPath)

// 监听进度
Task {
    for await progress in task.progressStream {
        if progress.percentage > 50 {
            task.cancel()  // 下载超过 50% 时取消
        }
    }
}

// 或直接取消
downloader.cancel()
```

## 错误处理

```swift
do {
    let result = try await downloader.download(url: url, to: outputPath)
} catch M3U8Error.parseFailed(let reason) {
    print("解析失败: \(reason)")
} catch M3U8Error.downloadFailed(let reason) {
    print("下载失败: \(reason)")
} catch M3U8Error.cancelled {
    print("下载已取消")
} catch {
    print("未知错误: \(error)")
}
```

### 错误类型

| 错误 | 描述 |
|------|------|
| `initializationFailed` | 下载器初始化失败 |
| `disposed` | 实例已被释放 |
| `invalidParameter` | 无效参数 |
| `parseFailed` | 解析失败 |
| `downloadFailed` | 下载失败 |
| `cancelled` | 操作被取消 |
| `unsupportedFeature` | 不支持的功能 |
| `networkError` | 网络错误 |
| `decryptionFailed` | 解密失败 |

## SwiftUI 集成

```swift
import SwiftUI
import M3U8DownloaderKit

struct DownloadView: View {
    @State private var progress: Double = 0
    @State private var isDownloading = false
    
    var body: some View {
        VStack {
            ProgressView(value: progress, total: 100)
            
            Button(isDownloading ? "下载中..." : "开始下载") {
                Task {
                    await startDownload()
                }
            }
            .disabled(isDownloading)
        }
    }
    
    func startDownload() async {
        isDownloading = true
        defer { isDownloading = false }
        
        do {
            let downloader = try M3U8Downloader()
            
            downloader.onProgress { progress in
                Task { @MainActor in
                    self.progress = progress.percentage
                }
            }
            
            let result = try await downloader.download(
                url: "https://example.com/playlist.m3u8",
                to: getOutputPath()
            )
            
            print("下载完成: \(result.formattedFileSize)")
        } catch {
            print("下载失败: \(error)")
        }
    }
    
    func getOutputPath() -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("video.mp4").path
    }
}
```

## 数据模型

### StreamInfo

```swift
struct StreamInfo {
    let id: String              // 流 ID
    let type: StreamType        // 类型: video, audio, subtitle
    let codec: String?          // 编解码器
    let bitrate: Int?           // 比特率 (bps)
    let resolution: String?     // 分辨率 (如 "1920x1080")
    let language: String?       // 语言代码
    let isEncrypted: Bool       // 是否加密
}
```

### DownloadProgress

```swift
struct DownloadProgress {
    let percentage: Double      // 进度百分比 (0-100)
    let speed: Int?             // 下载速度 (字节/秒)
    let downloadedBytes: Int?   // 已下载字节数
    let totalBytes: Int?        // 总字节数
    
    var formattedSpeed: String  // 格式化速度 (如 "1.5 MB/s")
    var formattedProgress: String  // 格式化进度 (如 "50.0%")
}
```

### DownloadResult

```swift
struct DownloadResult {
    let success: Bool           // 是否成功
    let outputFile: String?     // 输出文件路径
    let fileSize: Int?          // 文件大小 (字节)
    let duration: Double?       // 时长 (秒)
    let errorMessage: String?   // 错误信息
    
    var formattedFileSize: String   // 格式化文件大小
    var formattedDuration: String   // 格式化时长
}
```

## 线程安全

`M3U8Downloader` 被设计为线程安全的，可以在任何线程调用其方法。内部使用锁机制保护状态。

所有模型类型都符合 `Sendable` 协议，可以安全地在并发上下文中传递。

## 最佳实践

1. **及时释放资源**: 下载完成后调用 `dispose()` 释放资源
2. **错误处理**: 始终捕获并处理可能的错误
3. **进度更新**: 在主线程更新 UI
4. **配置复用**: 可以为多个下载任务复用相同的配置
5. **取消支持**: 长时间下载时提供取消选项

## 示例项目

示例项目使用 Swift Package Manager 管理，提供命令行演示应用。

### 项目结构

```
swift/
├── Package.swift                    # 主 SPM 包配置
├── Sources/
│   ├── M3U8DownloaderKit/          # Swift 包装层
│   └── M3U8DownloaderKit_C/        # C 桥接层
├── Tests/
│   └── M3U8DownloaderKitTests/     # 单元测试
└── Example/
    ├── Package.swift               # 演示应用包配置
    └── Sources/
        └── M3U8DemoApp/            # 命令行演示应用
```

### 运行演示应用

```bash
# 方式一：命令行运行
cd swift/Example
swift run M3U8DemoApp

# 方式二：在 Xcode 中打开
cd swift/Example
open Package.swift
```

### 在 Xcode 中测试主库

```bash
cd swift
open Package.swift
```

然后选择 scheme 运行测试或构建。

## 测试

运行单元测试：

```bash
cd swift
swift test
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
