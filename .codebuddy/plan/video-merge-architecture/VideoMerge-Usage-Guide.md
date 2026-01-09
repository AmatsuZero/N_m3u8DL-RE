# M3U8VideoMerge 使用指南

## 简介

M3U8VideoMerge 是 M3U8DownloaderKit 的可选模块，提供基于 AVFoundation 的视频合并功能。支持 iOS 15.0+ 和 macOS 12.0+。

## 特性

- ✅ 零依赖，使用系统原生 AVFoundation 框架
- ✅ 硬件加速支持
- ✅ 支持分批处理大量视频片段
- ✅ 支持分辨率不一致处理
- ✅ 实时进度监控
- ✅ 取消操作支持
- ✅ 详细的性能统计
- ✅ iOS 和 macOS 共享核心代码

## 安装

### CocoaPods

```ruby
# 仅基础下载功能
pod 'M3U8DownloaderKit'

# 包含视频合并功能
pod 'M3U8DownloaderKit/VideoMerge'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/AmatsuZero/N_m3u8DL-RE.git", from: "1.0.0")
]

// 基础功能
.product(name: "M3U8DownloaderKit", package: "N_m3u8DL-RE")

// 视频合并功能
.product(name: "M3U8VideoMerge", package: "N_m3u8DL-RE")
```

## 快速开始

### Objective-C

```objc
#import <M3U8DownloaderKitObjC/M3U8VideoMerge.h>

// 1. 注册处理器
M3U8AVFoundationProcessor *processor = [M3U8AVFoundationProcessor processor];
[[M3U8VideoProcessorRegistry sharedRegistry] registerProcessor:processor];

// 2. 创建合并请求
NSArray<NSURL *> *inputFiles = @[
    [NSURL fileURLWithPath:@"/path/to/video1.ts"],
    [NSURL fileURLWithPath:@"/path/to/video2.ts"],
    [NSURL fileURLWithPath:@"/path/to/video3.ts"]
];

NSURL *outputURL = [NSURL fileURLWithPath:@"/path/to/output.mp4"];

M3U8MergeOptions *options = [M3U8MergeOptions defaultOptions];
options.outputFormat = M3U8OutputFormatMP4;
options.scalingStrategy = M3U8ScalingStrategyScaleToFirst;

M3U8MergeRequest *request = [M3U8MergeRequest requestWithInputFiles:inputFiles
                                                           outputURL:outputURL
                                                             options:options];

// 3. 设置进度回调
request.progressHandler = ^(double progress) {
    NSLog(@"合并进度: %.1f%%", progress * 100);
};

// 4. 执行合并
[processor mergeWithRequest:request completion:^(M3U8MergeResult *result, NSError *error) {
    if (result.success) {
        NSLog(@"合并成功！");
        NSLog(@"输出文件: %@", result.outputURL.path);
        NSLog(@"视频时长: %.2f 秒", result.duration);
        NSLog(@"%@", [result.statistics formattedDescription]);
    } else {
        NSLog(@"合并失败: %@", error.localizedDescription);
    }
}];
```

### Swift

```swift
import M3U8VideoMerge

// 1. 注册处理器
let processor = M3U8AVFoundationProcessor.processor()
M3U8VideoProcessorRegistry.shared().register(processor)

// 2. 创建合并请求
let inputFiles = [
    URL(fileURLWithPath: "/path/to/video1.ts"),
    URL(fileURLWithPath: "/path/to/video2.ts"),
    URL(fileURLWithPath: "/path/to/video3.ts")
]

let outputURL = URL(fileURLWithPath: "/path/to/output.mp4")

let options = M3U8MergeOptions.default()
options.outputFormat = .MP4
options.scalingStrategy = .scaleToFirst

let request = M3U8MergeRequest(inputFiles: inputFiles,
                               outputURL: outputURL,
                               options: options)

// 3. 设置进度回调
request.progressHandler = { progress in
    print("合并进度: \(progress * 100)%")
}

// 4. 执行合并
processor.merge(with: request) { result, error in
    if let result = result, result.success {
        print("合并成功！")
        print("输出文件: \(result.outputURL?.path ?? "")")
        print("视频时长: \(result.duration) 秒")
        print(result.statistics.formattedDescription())
    } else {
        print("合并失败: \(error?.localizedDescription ?? "")")
    }
}
```

## 高级用法

### 自动选择最佳处理器

```objc
// 获取最佳可用处理器
[[M3U8VideoProcessorRegistry sharedRegistry] getBestProcessorWithCompletion:^(id<M3U8VideoProcessor> processor) {
    if (processor) {
        NSLog(@"使用处理器: %@", processor.name);
        [processor mergeWithRequest:request completion:^(M3U8MergeResult *result, NSError *error) {
            // 处理结果
        }];
    } else {
        NSLog(@"没有可用的处理器");
    }
}];
```

### 取消操作

```objc
M3U8CancellationToken *token = [[M3U8CancellationToken alloc] init];
request.cancellationToken = token;

// 开始合并
[processor mergeWithRequest:request completion:^(M3U8MergeResult *result, NSError *error) {
    if (result.cancelled) {
        NSLog(@"操作已取消");
    }
}];

// 在需要时取消
[token cancel];
```

### 自定义配置

```objc
M3U8MergeOptions *options = [M3U8MergeOptions defaultOptions];

// 输出格式
options.outputFormat = M3U8OutputFormatMP4;

// 分辨率缩放策略
options.scalingStrategy = M3U8ScalingStrategyAspectFit;

// 批次大小（处理大量文件时）
options.batchSize = 150;

// 优化网络传输
options.optimizeForNetworkUse = YES;

// 元数据
options.writeMetadata = YES;
options.metadata = @{
    @"title": @"我的视频",
    @"artist": @"作者名称"
};

// 详细日志
options.verboseLogging = YES;
```

### 查询功能支持

```objc
// 检查处理器是否支持特定功能
BOOL supportsHardwareAccel = [processor supportsFeature:M3U8VideoProcessorFeatureHardwareAcceleration];
BOOL supportsScaling = [processor supportsFeature:M3U8VideoProcessorFeatureResolutionScaling];

// 查询支持特定功能的所有处理器
[[M3U8VideoProcessorRegistry sharedRegistry] getProcessorsByFeature:M3U8VideoProcessorFeatureHardwareAcceleration
                                                          completion:^(NSArray<id<M3U8VideoProcessor>> *processors) {
    NSLog(@"支持硬件加速的处理器: %@", processors);
}];
```

## 性能优化建议

### iOS 平台

- 默认批次大小：100-200 个文件
- 建议在后台队列执行合并操作
- 监控内存使用，避免超过 200MB

### macOS 平台

- 默认批次大小：200-500 个文件
- 可以利用更强的硬件能力处理更大批次
- 优化磁盘 I/O 性能

### 通用建议

1. **分批处理**：超过 100 个文件时自动启用分批处理
2. **硬件加速**：AVFoundation 自动使用 GPU 加速
3. **内存管理**：使用 `@autoreleasepool` 处理大量文件
4. **错误处理**：实现重试机制，配置 `maxRetryCount`

## 错误处理

```objc
[processor mergeWithRequest:request completion:^(M3U8MergeResult *result, NSError *error) {
    if (error) {
        switch (error.code) {
            case 1001:
                NSLog(@"输入文件列表为空");
                break;
            case 1003:
                NSLog(@"文件不存在: %@", error.localizedDescription);
                break;
            case 2001:
                NSLog(@"无法创建导出会话");
                break;
            case 2002:
                NSLog(@"导出失败");
                break;
            default:
                NSLog(@"未知错误: %@", error.localizedDescription);
                break;
        }
    }
}];
```

## 常见问题

### Q: 支持哪些视频格式？

A: AVFoundation 支持大多数常见格式，包括：
- TS (MPEG-2 Transport Stream)
- MP4
- MOV
- M4V

### Q: 如何处理分辨率不一致的视频？

A: 使用 `scalingStrategy` 配置：
- `M3U8ScalingStrategyScaleToFirst`: 缩放到第一个视频的分辨率
- `M3U8ScalingStrategyAspectFit`: 保持宽高比，适应目标尺寸
- `M3U8ScalingStrategyAspectFill`: 保持宽高比，填充目标尺寸

### Q: 合并大量文件时内存占用过高怎么办？

A: 系统会自动启用分批处理。你也可以手动调整 `batchSize` 参数。

### Q: 如何获取合并进度？

A: 设置 `request.progressHandler` 回调，参数范围为 0.0-1.0。

### Q: 支持后台执行吗？

A: iOS 支持在前台启动后在后台继续执行。macOS 没有限制。

## API 参考

完整的 API 文档请参考头文件中的注释：

- `M3U8VideoProcessor.h` - 处理器协议
- `M3U8MergeRequest.h` - 合并请求
- `M3U8MergeOptions.h` - 配置选项
- `M3U8MergeResult.h` - 合并结果
- `M3U8MergeStatistics.h` - 性能统计
- `M3U8VideoProcessorRegistry.h` - 处理器注册表
- `M3U8AVFoundationProcessor.h` - AVFoundation 处理器

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
