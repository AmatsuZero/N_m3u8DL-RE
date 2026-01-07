# N_m3u8DL-RE.Core

iOS平台的M3U8下载核心库 - 纯C#实现，无UI依赖，支持灵活的视频处理策略。

## 📦 项目结构

```
N_m3u8DL-RE.Core/
├── API/                          # 公共API接口层
│   └── M3U8DownloaderAPI.cs     # 主API接口
├── Abstraction/                  # 抽象接口
│   ├── ILogger.cs               # 日志接口
│   └── IDownloadProgressCallback.cs  # 进度回调接口
├── Downloader/                   # 下载器
│   ├── IDownloader.cs           # 下载器接口
│   └── SimpleDownloader.cs      # 简单下载器实现
├── VideoProcessor/               # 视频处理器
│   ├── IVideoProcessor.cs       # 视频处理器接口
│   ├── BasicVideoProcessor.cs   # 基础处理器（纯C#）
│   └── VideoProcessorFactory.cs # 处理器工厂和管理器
├── Crypto/                       # 加密解密
│   ├── AESUtil.cs               # AES工具
│   ├── ChaCha20Util.cs          # ChaCha20工具
│   └── CSChaCha20.cs            # ChaCha20实现
└── Util/                         # 工具类
    ├── DownloadUtil.cs          # 下载工具
    ├── ImageHeaderUtil.cs       # 图片头处理
    └── OtherUtil.cs             # 其他工具
```

## 🚀 快速开始

### 1. 基础用法

```csharp
using N_m3u8DL_RE.Core.API;
using N_m3u8DL_RE.Core.Abstraction;

// 创建自定义日志记录器（可选）
public class MyLogger : ILogger
{
    public void Debug(string message) => Console.WriteLine($"[DEBUG] {message}");
    public void Info(string message) => Console.WriteLine($"[INFO] {message}");
    public void Warn(string message) => Console.WriteLine($"[WARN] {message}");
    public void Error(string message) => Console.WriteLine($"[ERROR] {message}");
}

// 初始化下载器
var logger = new MyLogger();
var downloader = new M3U8DownloaderAPI(logger);

// 配置选项
var config = new DownloaderConfiguration
{
    MaxConcurrency = 8,
    TimeoutSeconds = 30,
    RetryCount = 3
};

await downloader.InitializeAsync(config);

// 下载M3U8
var request = new DownloadRequest
{
    Url = "https://example.com/playlist.m3u8",
    OutputPath = "/path/to/output.mp4"
};

var result = await downloader.DownloadAsync(request);

if (result.Success)
{
    Console.WriteLine($"Download completed: {result.OutputFile}");
}
else
{
    Console.WriteLine($"Download failed: {result.ErrorMessage}");
}
```

### 2. 带进度回调

```csharp
// 创建进度回调
public class MyProgressCallback : IDownloadProgressCallback
{
    public void OnProgress(DownloadProgress progress)
    {
        Console.WriteLine($"Progress: {progress.Percentage:F2}% " +
                         $"Speed: {progress.SpeedMBps:F2} MB/s " +
                         $"ETA: {progress.EstimatedTimeRemaining}");
    }

    public void OnCompleted(string message)
    {
        Console.WriteLine($"Completed: {message}");
    }

    public void OnError(string error)
    {
        Console.WriteLine($"Error: {error}");
    }
}

var progressCallback = new MyProgressCallback();
var result = await downloader.DownloadAsync(request, progressCallback);
```

### 3. 解析M3U8

```csharp
var parseResult = await downloader.ParseAsync("https://example.com/playlist.m3u8");

if (parseResult.Success)
{
    foreach (var stream in parseResult.Streams)
    {
        Console.WriteLine($"Stream: {stream.Type} - {stream.Resolution} - {stream.Bitrate} bps");
    }
}
```

### 4. 高级用法 - 视频处理器

```csharp
// 获取视频处理器管理器
var processorManager = downloader.GetVideoProcessorManager();

// 检查功能可用性
bool canDecrypt = await processorManager.IsFeatureAvailableAsync("decrypt");
bool canMerge = await processorManager.IsFeatureAvailableAsync("merge");

// 手动解密文件
var decryptRequest = new DecryptionRequest
{
    SourceFile = "/path/to/encrypted.mp4",
    DestinationFile = "/path/to/decrypted.mp4",
    Keys = new[] { "kid:key" },
    Kid = "kid"
};

var decryptResult = await processorManager.DecryptAsync(decryptRequest);

// 合并文件
var mergeRequest = new MergeRequest
{
    InputFiles = new List<string> { "file1.mp4", "file2.mp4" },
    OutputFile = "merged.mp4"
};

var mergeResult = await processorManager.MergeAsync(mergeRequest);
```

## 🎯 核心特性

### 1. 接口优先设计

所有核心功能都通过接口定义，支持依赖注入和自定义实现：

- `ILogger` - 自定义日志输出
- `IDownloadProgressCallback` - 自定义进度回调
- `IDownloader` - 自定义下载器
- `IVideoProcessor` - 自定义视频处理器

### 2. 灵活的视频处理策略

支持多种视频处理器，自动选择最佳可用实现：

- **BasicVideoProcessor** - 纯C#实现，始终可用
- **iOS Native Processor** - iOS原生VideoToolbox（待实现）
- **FFmpeg Processor** - FFmpeg集成（可选）

### 3. 无外部工具依赖

核心功能不依赖外部工具（ffmpeg、mp4decrypt等），完全使用C#实现。

### 4. 取消令牌支持

所有异步操作都支持`CancellationToken`，可以随时取消操作。

### 5. 加密解密支持

内置AES-128和ChaCha20解密支持，无需外部工具。

## 📋 依赖项

- .NET 10.0
- N_m3u8DL-RE.Common
- N_m3u8DL-RE.Parser

## 🔧 配置选项

### DownloaderConfiguration

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| MaxConcurrency | int | 8 | 最大并发下载数 |
| TimeoutSeconds | int | 30 | 下载超时时间（秒） |
| RetryCount | int | 3 | 重试次数 |
| TempDirectory | string? | null | 临时文件目录 |
| AutoCleanup | bool | true | 是否自动清理临时文件 |
| CustomHeaders | Dictionary | {} | 自定义HTTP头 |

## 🎨 架构设计

### 分层架构

```
┌─────────────────────────────────────┐
│         API Layer (公共接口)         │
│    M3U8DownloaderAPI                │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│      Business Logic Layer           │
│  VideoProcessorManager              │
│  DownloadManager                    │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│      Strategy Layer (策略层)        │
│  VideoProcessorFactory              │
│  IVideoProcessor Implementations    │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│      Core Layer (核心功能)          │
│  Downloader, Crypto, Util           │
└─────────────────────────────────────┘
```

### 策略模式

视频处理器使用策略模式，支持运行时选择最佳实现：

```
IVideoProcessor (接口)
    ↓
    ├── BasicVideoProcessor (优先级: 1)
    ├── iOSNativeProcessor (优先级: 10)
    └── FFmpegProcessor (优先级: 5)
```

## 🚧 开发状态

### ✅ 已完成

- [x] 核心项目结构
- [x] 日志接口抽象
- [x] 进度回调接口
- [x] 下载器重构
- [x] 加密解密模块
- [x] 视频处理器接口
- [x] 基础视频处理器
- [x] 处理器工厂和管理器
- [x] 公共API接口层

### 🔄 进行中

- [ ] 完整的下载逻辑实现
- [ ] M3U8解析集成
- [ ] iOS原生视频处理器

### 📅 计划中

- [ ] 下载策略接口
- [ ] 异步下载接口
- [ ] 单元测试
- [ ] 性能优化
- [ ] XCFramework打包

## 📖 API文档

详细的API文档请参考代码注释和示例。

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

与主项目保持一致。
