# 快速开始指南 - 使用 N_m3u8DL-RE.Core 库

本指南展示如何在你的项目中使用 N_m3u8DL-RE.Core 核心库。

## 📦 安装

### 方式1: 项目引用
在你的 `.csproj` 文件中添加：

```xml
<ItemGroup>
  <ProjectReference Include="path/to/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj" />
</ItemGroup>
```

### 方式2: NuGet包（如果已发布）
```bash
dotnet add package N_m3u8DL-RE.Core
```

## 🚀 基本使用

### 1. 下载HLS流

```csharp
using N_m3u8DL_RE.Core.DownloadManager;
using N_m3u8DL_RE.Core.Config;
using N_m3u8DL_RE.Parser;
using N_m3u8DL_RE.Common.Entity;

// 创建解析器配置
var parserConfig = new ParserConfig
{
    Url = "https://example.com/playlist.m3u8",
    Headers = new Dictionary<string, string>()
};

// 解析流
var extractor = new StreamExtractor(parserConfig);
var streams = await extractor.ExtractStreamsAsync();

// 创建下载配置
var downloaderConfig = new DownloaderConfig
{
    MaxThreads = 8,
    RetryCount = 3
};

// 创建下载管理器
var downloadManager = new SimpleDownloadManager(
    downloaderConfig,
    streams,
    outputPath: "./output"
);

// 开始下载
await downloadManager.StartDownloadAsync();
```

### 2. 录制直播流

```csharp
using N_m3u8DL_RE.Core.DownloadManager;

// 创建直播录制管理器
var liveRecordManager = new SimpleLiveRecordManager2(
    config,
    streamSpec,
    outputPath
);

// 开始录制
await liveRecordManager.StartRecordAsync();

// 停止录制（在需要时）
await liveRecordManager.StopRecordAsync();
```

### 3. 使用加密工具

```csharp
using N_m3u8DL_RE.Core.Crypto;

// AES解密
var aesUtil = new AESUtil();
var decryptedData = aesUtil.Decrypt(
    encryptedData,
    key,
    iv,
    method: "AES-128-CBC"
);

// ChaCha20解密
var chachaUtil = new ChaCha20Util();
var decryptedData = chachaUtil.Decrypt(
    encryptedData,
    key,
    nonce
);
```

### 4. 文件合并

```csharp
using N_m3u8DL_RE.Core.Util;

// 合并视频片段
var mergeUtil = new MergeUtil();
await mergeUtil.MergeFilesAsync(
    inputFiles: new[] { "part1.ts", "part2.ts", "part3.ts" },
    outputFile: "output.mp4",
    deleteSource: true
);
```

### 5. MP4解密

```csharp
using N_m3u8DL_RE.Core.Util;

// 解密MP4文件
var mp4DecryptUtil = new MP4DecryptUtil();
await mp4DecryptUtil.DecryptAsync(
    inputFile: "encrypted.mp4",
    outputFile: "decrypted.mp4",
    key: keyBytes,
    kid: kidBytes
);
```

## 🎨 创建自定义处理器

### 自定义URL处理器

```csharp
using N_m3u8DL_RE.Core.Processor;

public class MyCustomUrlProcessor : UrlProcessor
{
    public override string Process(string url, string baseUrl)
    {
        // 自定义URL处理逻辑
        if (url.StartsWith("custom://"))
        {
            return ConvertCustomUrl(url);
        }
        
        return base.Process(url, baseUrl);
    }
    
    private string ConvertCustomUrl(string url)
    {
        // 实现自定义转换逻辑
        return url.Replace("custom://", "https://");
    }
}
```

### 自定义内容处理器

```csharp
using N_m3u8DL_RE.Core.Processor;

public class MyContentProcessor : ContentProcessor
{
    public override async Task<byte[]> ProcessAsync(byte[] content)
    {
        // 自定义内容处理逻辑
        // 例如：解密、解压缩等
        
        return await Task.FromResult(ProcessedContent(content));
    }
    
    private byte[] ProcessedContent(byte[] content)
    {
        // 实现处理逻辑
        return content;
    }
}
```

## 🔧 高级配置

### 配置下载器

```csharp
using N_m3u8DL_RE.Core.Config;
using N_m3u8DL_RE.Core.Enum;

var config = new DownloaderConfig
{
    // 最大并发线程数
    MaxThreads = 16,
    
    // 重试次数
    RetryCount = 5,
    
    // 超时时间（秒）
    Timeout = 30,
    
    // 解密引擎
    DecryptEngine = DecryptEngine.Native,
    
    // 自定义Headers
    Headers = new Dictionary<string, string>
    {
        ["User-Agent"] = "MyApp/1.0",
        ["Referer"] = "https://example.com"
    }
};
```

### 配置解析器

```csharp
using N_m3u8DL_RE.Parser.Config;

var parserConfig = new ParserConfig
{
    Url = "https://example.com/manifest.mpd",
    
    // 自定义Headers
    Headers = new Dictionary<string, string>
    {
        ["Authorization"] = "Bearer token"
    },
    
    // 自定义URL处理器
    UrlProcessor = new MyCustomUrlProcessor(),
    
    // 自定义内容处理器
    ContentProcessor = new MyContentProcessor()
};
```

## 📊 进度监控

```csharp
using N_m3u8DL_RE.Core.DownloadManager;
using N_m3u8DL_RE.Core.Entity;

var downloadManager = new SimpleDownloadManager(config, streams, outputPath);

// 订阅进度事件
downloadManager.OnProgress += (sender, progress) =>
{
    Console.WriteLine($"进度: {progress.Percentage:F2}%");
    Console.WriteLine($"速度: {progress.Speed} MB/s");
    Console.WriteLine($"已下载: {progress.Downloaded}/{progress.Total}");
};

// 订阅完成事件
downloadManager.OnCompleted += (sender, result) =>
{
    Console.WriteLine($"下载完成: {result.OutputFile}");
};

// 订阅错误事件
downloadManager.OnError += (sender, error) =>
{
    Console.WriteLine($"错误: {error.Message}");
};

await downloadManager.StartDownloadAsync();
```

## 🎯 实际应用示例

### 示例1: 批量下载

```csharp
var urls = new[]
{
    "https://example.com/video1.m3u8",
    "https://example.com/video2.m3u8",
    "https://example.com/video3.m3u8"
};

foreach (var url in urls)
{
    var parserConfig = new ParserConfig { Url = url };
    var extractor = new StreamExtractor(parserConfig);
    var streams = await extractor.ExtractStreamsAsync();
    
    var downloadManager = new SimpleDownloadManager(
        config,
        streams,
        $"./output/{Path.GetFileNameWithoutExtension(url)}"
    );
    
    await downloadManager.StartDownloadAsync();
}
```

### 示例2: 带认证的下载

```csharp
var config = new DownloaderConfig
{
    Headers = new Dictionary<string, string>
    {
        ["Authorization"] = "Bearer YOUR_TOKEN",
        ["Cookie"] = "session=YOUR_SESSION"
    }
};

var parserConfig = new ParserConfig
{
    Url = "https://example.com/protected/playlist.m3u8",
    Headers = config.Headers
};

var extractor = new StreamExtractor(parserConfig);
var streams = await extractor.ExtractStreamsAsync();

var downloadManager = new SimpleDownloadManager(config, streams, "./output");
await downloadManager.StartDownloadAsync();
```

### 示例3: 流过滤

```csharp
using N_m3u8DL_RE.Core.Util;
using N_m3u8DL_RE.Core.Entity;

// 提取所有流
var streams = await extractor.ExtractStreamsAsync();

// 创建过滤器
var filter = new StreamFilter
{
    VideoCodec = "avc1",  // 只要H.264编码
    MinBandwidth = 1000000,  // 最小带宽1Mbps
    MaxBandwidth = 5000000,  // 最大带宽5Mbps
    Language = "zh-CN"  // 中文音轨
};

// 应用过滤
var filteredStreams = FilterUtil.FilterStreams(streams, filter);

// 下载过滤后的流
var downloadManager = new SimpleDownloadManager(
    config,
    filteredStreams,
    "./output"
);
await downloadManager.StartDownloadAsync();
```

## 🐛 错误处理

```csharp
try
{
    var downloadManager = new SimpleDownloadManager(config, streams, outputPath);
    await downloadManager.StartDownloadAsync();
}
catch (HttpRequestException ex)
{
    Console.WriteLine($"网络错误: {ex.Message}");
}
catch (UnauthorizedAccessException ex)
{
    Console.WriteLine($"权限错误: {ex.Message}");
}
catch (Exception ex)
{
    Console.WriteLine($"未知错误: {ex.Message}");
}
```

## 📚 更多资源

- [完整API文档](./docs/API.md)
- [架构说明](./ARCHITECTURE.md)
- [示例项目](./examples/)
- [常见问题](./FAQ.md)

## 💡 提示

1. **性能优化**: 根据网络情况调整 `MaxThreads` 参数
2. **内存管理**: 大文件下载时注意内存使用
3. **错误重试**: 合理设置 `RetryCount` 避免无限重试
4. **日志记录**: 使用 `N_m3u8DL_RE.Common.Log` 记录日志

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

遵循项目原有许可证。
