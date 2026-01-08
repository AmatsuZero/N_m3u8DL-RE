# M3U8 Downloader Demo

这是一个使用 M3U8DownloaderKit 的演示应用，展示如何使用 Swift 包装层进行流媒体解析和下载。

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
cd swift/Example

# 构建并运行
swift run M3U8DemoApp
```

### 方式二：在 Xcode 中打开

```bash
# 进入 Example 目录
cd swift/Example

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
5. **查看下载器状态** - 显示当前下载器版本和状态
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

### 解析流媒体

```swift
import M3U8DownloaderKit

let downloader = try M3U8Downloader()
let result = try await downloader.parse(url: "https://example.com/stream.m3u8")

for stream in result.streams {
    print("Stream: \(stream.type) - \(stream.resolution ?? "N/A")")
}
```

### 下载流媒体

```swift
import M3U8DownloaderKit

let downloader = try M3U8Downloader()
let result = try await downloader.download(
    url: "https://example.com/stream.m3u8",
    to: "/path/to/output.mp4"
)

print("下载完成: \(result.outputFile ?? "N/A")")
```

## 注意事项

1. 确保已正确配置 XCFramework 或动态库
2. 某些测试流可能需要网络连接
3. 下载功能会在当前目录创建输出文件

## 许可证

MIT License
