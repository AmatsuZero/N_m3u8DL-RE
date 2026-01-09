# M3U8 Downloader Demo

这是一个使用 M3U8DownloaderKit 的演示应用，展示如何使用 Objective-C 封装层进行流媒体解析和下载。

## 项目结构

```
Example/
├── Package.swift                    # SPM 包配置
├── README.md                        # 本文档
└── Sources/
    └── M3U8DemoApp/
        └── main.swift               # 命令行演示应用
```

## 运行方式

### 方式一：命令行运行

```bash
# 进入 Example 目录
cd Example

# 构建并运行
swift run M3U8DemoApp
```

### 方式二：在 Xcode 中打开

```bash
# 进入 Example 目录
cd Example

# 在 Xcode 中打开
open Package.swift
```

在 Xcode 中选择 `M3U8DemoApp` scheme，然后运行。

## 功能演示

演示应用提供以下功能：

1. **解析测试流** - 解析预设的测试流 URL
2. **下载测试流** - 下载预设的测试流
3. **自定义 URL 解析** - 解析用户输入的 URL
4. **自定义 URL 下载** - 下载用户输入的 URL
5. **查看下载器状态** - 显示当前下载器状态
6. **运行演示测试** - 运行自动化演示测试

## 测试流 URL

演示应用内置了以下测试流：

| 名称 | 格式 | URL |
|------|------|-----|
| Apple Basic HLS | HLS | `https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8` |
| Apple Advanced HEVC | HLS | `https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8` |
| DASH Clear 1080p | DASH | `https://media.axprod.net/TestVectors/v7-Clear/Manifest_1080p.mpd` |
| DASH Multi Audio | DASH | `https://dash.akamaized.net/dash264/TestCases/2c/qualcomm/1/MultiResMPEG2.mpd` |

## 使用示例

### 解析流媒体 (Objective-C)

```objc
#import <M3U8DownloaderKit/M3U8DownloaderKit.h>

// 创建配置
M3U8Configuration *config = [[M3U8Configuration alloc] init];
config.maxConcurrency = 8;
config.timeoutSeconds = 30;

// 创建下载器
M3U8Downloader *downloader = [[M3U8Downloader alloc] initWithConfiguration:config];

// 解析流
[downloader parseURL:@"https://example.com/stream.m3u8" 
          completion:^(M3U8ParseResult *result, NSError *error) {
    if (error) {
        NSLog(@"解析失败: %@", error.localizedDescription);
        return;
    }
    
    for (M3U8StreamInfo *stream in result.streams) {
        NSLog(@"Stream: %@ - %@", @(stream.type), stream.resolution ?: @"N/A");
    }
}];
```

### 解析流媒体 (Swift)

```swift
import M3U8DownloaderKitObjC

// 创建配置
let config = M3U8Configuration()
config.maxConcurrency = 8
config.timeoutSeconds = 30

// 创建下载器
let downloader = M3U8Downloader(configuration: config)

// 解析流
downloader?.parse("https://example.com/stream.m3u8") { result, error in
    if let error = error {
        print("解析失败: \(error.localizedDescription)")
        return
    }
    
    guard let result = result else { return }
    
    for stream in result.streams {
        print("Stream: \(stream.type) - \(stream.resolution ?? "N/A")")
    }
}
```

### 下载流媒体 (Swift)

```swift
import M3U8DownloaderKitObjC

let downloader = M3U8Downloader(configuration: M3U8Configuration.default())

let options = M3U8DownloadOptions()
options.autoSelectBestQuality = true

downloader?.download("https://example.com/stream.m3u8", 
                     to: "/path/to/output.mp4",
                     options: options) { result, error in
    if let error = error {
        print("下载失败: \(error.localizedDescription)")
        return
    }
    
    print("下载完成: \(result?.outputFile ?? "N/A")")
}

// 使用完毕后释放资源
downloader?.dispose()
```

## 架构说明

```
M3U8DownloaderKit (Pod 库)
├── M3U8DownloaderKitObjC/        # Objective-C 封装层
│   ├── M3U8Downloader.h/m        # 主下载器类
│   ├── M3U8Types.h/m             # 数据类型
│   ├── M3U8Error.h/m             # 错误定义
│   └── m3u8dl.h                  # C API 头文件
└── M3U8Core.xcframework/         # 底层 C 库 (.NET NativeAOT)
```

## 注意事项

1. 确保已正确配置 M3U8Core.xcframework
2. 某些测试流可能需要网络连接
3. 下载功能会在当前目录创建输出文件
4. 使用完毕后记得调用 `dispose()` 释放资源

## 许可证

MIT License
