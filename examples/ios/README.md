# iOS 示例代码

本目录包含在 iOS 应用中使用 N_m3u8DL-RE Core Library 的示例代码。

## 📁 文件说明

### Objective-C 示例
- **M3U8Downloader.h**: Objective-C 封装类头文件
- **M3U8Downloader.m**: Objective-C 封装类实现

### Swift 示例
- **M3U8Downloader.swift**: Swift 封装类

## 🚀 使用方法

### Objective-C

```objective-c
#import "M3U8Downloader.h"

// 获取单例
M3U8Downloader *downloader = [M3U8Downloader sharedDownloader];

// 开始下载
[downloader downloadURL:@"https://example.com/playlist.m3u8"
             outputPath:@"/path/to/output.mp4"
             onProgress:^(int progress, long long downloadedBytes, long long totalBytes) {
                 NSLog(@"下载进度: %d%%", progress);
             }
           onCompletion:^(BOOL success, NSString *outputPath, NSError *error) {
               if (success) {
                   NSLog(@"下载完成: %@", outputPath);
               } else {
                   NSLog(@"下载失败: %@", error.localizedDescription);
               }
           }];

// 取消下载
[downloader cancel];

// 获取版本信息
NSString *version = [downloader libraryVersion];
NSString *apiVersion = [downloader apiVersion];
```

### Swift

```swift
import Foundation

// 获取单例
let downloader = M3U8Downloader.shared

// 开始下载
downloader.download(
    url: "https://example.com/playlist.m3u8",
    outputPath: "/path/to/output.mp4",
    onProgress: { progress, downloaded, total in
        print("下载进度: \(progress)%")
    },
    onCompletion: { success, output in
        if success {
            print("下载完成: \(output ?? "")")
        } else {
            print("下载失败")
        }
    }
)

// 取消下载
downloader.cancel()

// 获取版本信息
print("Library Version: \(downloader.libraryVersion)")
print("API Version: \(downloader.apiVersion)")
```

## 🔧 集成步骤

### 1. 添加 XCFramework

将 `N_m3u8DL_RE_Core.xcframework` 添加到你的 Xcode 项目中。

### 2. 复制示例代码

根据你的项目语言，复制相应的示例文件到项目中：

- **Objective-C 项目**: 复制 `M3U8Downloader.h` 和 `M3U8Downloader.m`
- **Swift 项目**: 复制 `M3U8Downloader.swift`
- **混合项目**: 可以同时使用两者

### 3. 配置 Bridging Header（仅 Swift 项目）

如果是纯 Swift 项目，需要创建 Bridging Header：

**YourProject-Bridging-Header.h**
```objective-c
#import <N_m3u8DL_RE_Core/N_m3u8DL_RE_Core.h>
```

### 4. 使用封装类

在你的代码中使用 `M3U8Downloader` 类进行下载。

## 📝 功能特性

### M3U8Downloader 类提供的功能

- ✅ **单例模式**: 全局共享实例
- ✅ **异步下载**: 不阻塞主线程
- ✅ **进度回调**: 实时获取下载进度
- ✅ **完成回调**: 下载完成或失败通知
- ✅ **取消支持**: 可随时取消下载
- ✅ **版本查询**: 获取库和 API 版本
- ✅ **错误处理**: 完善的错误处理机制

## ⚠️ 注意事项

### 1. 线程安全

封装类内部使用串行队列处理下载，确保线程安全。回调会自动切换到主线程。

### 2. 内存管理

- Objective-C 版本使用 ARC 自动管理内存
- Swift 版本使用自动引用计数
- 库返回的字符串会自动释放

### 3. 权限配置

在 `Info.plist` 中添加必要的权限：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 4. 文件路径

确保输出路径有写入权限，建议使用：
- Documents 目录
- Temporary 目录
- Cache 目录

```swift
// Swift 示例
let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
let outputPath = "\(documentsPath)/output.mp4"
```

```objective-c
// Objective-C 示例
NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
NSString *outputPath = [documentsPath stringByAppendingPathComponent:@"output.mp4"];
```

## 🔍 调试技巧

### 启用详细日志

在初始化后，库会输出日志到控制台。查看 Xcode 控制台获取详细信息。

### 检查返回值

所有 API 调用都会返回状态码：
- `0`: 成功
- 负数: 错误码

### 常见错误码

- `-1`: 一般错误
- `-2`: 无效的 URL
- `-3`: 无效的输出路径

## 📚 更多资源

- [iOS Library 集成指南](../../docs/iOS-Library-Integration.md)
- [架构文档](../../ARCHITECTURE.md)
- [API 参考](../../docs/iOS-Library-Integration.md#-api-参考)

## 📄 许可证

遵循项目原有许可证。
