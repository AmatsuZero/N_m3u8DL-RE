# N_m3u8DL-RE iOS SDK 集成指南

本文档介绍如何在 iOS 项目中集成和使用 N_m3u8DL-RE SDK。

## 目录

- [系统要求](#系统要求)
- [编译构建](#编译构建)
- [集成方法](#集成方法)
- [API参考](#api参考)
- [使用示例](#使用示例)
- [常见问题](#常见问题)

## 系统要求

- macOS 12.0+（用于开发）
- Xcode 15.0+
- iOS 14.2+ 目标平台
- .NET 9.0 SDK（用于编译）

## 编译构建

### 1. 安装 .NET SDK

如果尚未安装本地 .NET SDK：

```bash
# 运行安装脚本
./dotnet-install.sh
```

### 2. 编译静态库

```bash
# 编译所有架构（启用AOT）
./build-ios.sh

# 或仅编译特定架构
./build-ios.sh --arch ios-arm64          # iOS真机
./build-ios.sh --arch iossimulator-arm64 # 模拟器(Apple Silicon)
./build-ios.sh --arch iossimulator-x64   # 模拟器(Intel)

# 禁用AOT编译（调试用）
./build-ios.sh --no-aot --debug
```

### 3. 创建 XCFramework

```bash
# 使用默认设置
./build-xcframework.sh

# 或自定义框架名称
./build-xcframework.sh --name MyM3U8Kit
```

## 集成方法

### 方法一：XCFramework（推荐）

1. 将 `build/xcframework/M3U8DownloaderKit.xcframework` 拖入 Xcode 项目
2. 确保 "Embed & Sign" 或 "Do Not Embed"（静态库）已选中
3. 在 Build Settings 中配置：
   - Other Linker Flags: `-lc++ -lz -liconv`

### 方法二：手动集成

1. 将静态库 (`libM3U8DownloaderKit.a`) 添加到项目
2. 将头文件目录添加到 Header Search Paths
3. 配置链接器标志

## API参考

### 初始化

```c
// 初始化下载器实例
// 返回实例ID，失败返回-1
m3u8dl_instance_t m3u8dl_init(const char* config_json);

// 释放实例
void m3u8dl_dispose(m3u8dl_instance_t instance_id);

// 释放所有实例
void m3u8dl_dispose_all(void);
```

### 回调设置

```c
// 进度回调
typedef void (*m3u8dl_progress_callback_t)(
    m3u8dl_instance_t instance_id,
    int32_t percentage,
    const char* status_json
);

// 日志回调
typedef void (*m3u8dl_log_callback_t)(
    m3u8dl_log_level_t level,
    const char* message
);

// 完成回调
typedef void (*m3u8dl_completion_callback_t)(
    m3u8dl_instance_t instance_id,
    m3u8dl_bool_t success,
    const char* result_json
);

// 设置回调
void m3u8dl_set_progress_callback(m3u8dl_progress_callback_t callback);
void m3u8dl_set_log_callback(m3u8dl_log_callback_t callback);
void m3u8dl_set_completion_callback(m3u8dl_completion_callback_t callback);
```

### 解析功能

```c
// 同步解析
char* m3u8dl_parse(m3u8dl_instance_t instance_id, const char* url);

// 异步解析
int32_t m3u8dl_parse_async(m3u8dl_instance_t instance_id, const char* url);
```

### 下载功能

```c
// 同步下载
char* m3u8dl_download(m3u8dl_instance_t instance_id, const char* request_json);

// 异步下载
int32_t m3u8dl_download_async(m3u8dl_instance_t instance_id, const char* request_json);

// 取消下载
void m3u8dl_cancel(m3u8dl_instance_t instance_id);
```

### 功能查询

```c
// 获取可用处理器列表
char* m3u8dl_get_processors(m3u8dl_instance_t instance_id);

// 检查功能支持
m3u8dl_bool_t m3u8dl_is_feature_supported(
    m3u8dl_instance_t instance_id,
    const char* feature
);

// 获取版本信息
char* m3u8dl_get_version(void);
```

### 内存管理

```c
// 释放字符串
void m3u8dl_free_string(char* ptr);

// 通用内存分配/释放
void* m3u8dl_alloc(int32_t size);
void m3u8dl_free(void* ptr);
```

## 使用示例

### Swift 示例

```swift
import Foundation

// Swift桥接包装类
class M3U8Downloader {
    private var instanceId: Int32 = -1
    
    init(config: [String: Any]? = nil) {
        let configJson = config.flatMap { try? JSONSerialization.data(withJSONObject: $0) }
        let configStr = configJson.flatMap { String(data: $0, encoding: .utf8) }
        
        instanceId = m3u8dl_init(configStr)
    }
    
    deinit {
        if instanceId > 0 {
            m3u8dl_dispose(instanceId)
        }
    }
    
    func parse(url: String) -> ParseResult? {
        guard instanceId > 0 else { return nil }
        
        let result = m3u8dl_parse(instanceId, url)
        defer { m3u8dl_free_string(result) }
        
        guard let resultStr = result,
              let data = String(cString: resultStr).data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(ParseResult.self, from: data)
    }
    
    func download(url: String, outputPath: String) -> DownloadResult? {
        guard instanceId > 0 else { return nil }
        
        let request: [String: Any] = [
            "url": url,
            "outputPath": outputPath,
            "autoSelectBestQuality": true
        ]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: request),
              let requestStr = String(data: requestData, encoding: .utf8) else {
            return nil
        }
        
        let result = m3u8dl_download(instanceId, requestStr)
        defer { m3u8dl_free_string(result) }
        
        guard let resultStr = result,
              let data = String(cString: resultStr).data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(DownloadResult.self, from: data)
    }
    
    func cancel() {
        if instanceId > 0 {
            m3u8dl_cancel(instanceId)
        }
    }
}

// 数据模型
struct ParseResult: Codable {
    let success: Bool
    let errorMessage: String?
    let streams: [StreamInfo]?
}

struct StreamInfo: Codable {
    let id: String?
    let type: String?
    let codec: String?
    let bitrate: Int64?
    let resolution: String?
    let language: String?
    let isEncrypted: Bool
}

struct DownloadResult: Codable {
    let success: Bool
    let outputFile: String?
    let fileSize: Int64?
    let duration: Double?
    let errorMessage: String?
}

// 使用示例
class DownloadManager {
    static let shared = DownloadManager()
    private var downloader: M3U8Downloader?
    
    func initialize() {
        // 设置回调（需要在C层面处理）
        downloader = M3U8Downloader(config: [
            "maxConcurrency": 4,
            "timeoutSeconds": 30
        ])
    }
    
    func downloadVideo(url: String, to path: String, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let result = self?.downloader?.download(url: url, outputPath: path) else {
                DispatchQueue.main.async {
                    completion(false, "Download failed")
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(result.success, result.errorMessage)
            }
        }
    }
}
```

### Objective-C 示例

```objc
#import <Foundation/Foundation.h>
#import <m3u8dl.h>

@interface M3U8DownloaderObjC : NSObject

@property (nonatomic, readonly) int32_t instanceId;

- (instancetype)initWithConfig:(NSDictionary *)config;
- (NSDictionary *)parseURL:(NSString *)url;
- (NSDictionary *)downloadURL:(NSString *)url toPath:(NSString *)outputPath;
- (void)cancel;

@end

@implementation M3U8DownloaderObjC

- (instancetype)initWithConfig:(NSDictionary *)config {
    self = [super init];
    if (self) {
        NSString *configJson = nil;
        if (config) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:config options:0 error:nil];
            configJson = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        _instanceId = m3u8dl_init(configJson.UTF8String);
    }
    return self;
}

- (void)dealloc {
    if (_instanceId > 0) {
        m3u8dl_dispose(_instanceId);
    }
}

- (NSDictionary *)parseURL:(NSString *)url {
    if (_instanceId <= 0) return nil;
    
    char *result = m3u8dl_parse(_instanceId, url.UTF8String);
    if (!result) return nil;
    
    NSString *jsonStr = [NSString stringWithUTF8String:result];
    m3u8dl_free_string(result);
    
    NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

- (NSDictionary *)downloadURL:(NSString *)url toPath:(NSString *)outputPath {
    if (_instanceId <= 0) return nil;
    
    NSDictionary *request = @{
        @"url": url,
        @"outputPath": outputPath,
        @"autoSelectBestQuality": @YES
    };
    
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:request options:0 error:nil];
    NSString *requestJson = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
    
    char *result = m3u8dl_download(_instanceId, requestJson.UTF8String);
    if (!result) return nil;
    
    NSString *jsonStr = [NSString stringWithUTF8String:result];
    m3u8dl_free_string(result);
    
    NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

- (void)cancel {
    if (_instanceId > 0) {
        m3u8dl_cancel(_instanceId);
    }
}

@end

// 使用示例
void exampleUsage() {
    M3U8DownloaderObjC *downloader = [[M3U8DownloaderObjC alloc] initWithConfig:nil];
    
    // 解析流信息
    NSDictionary *parseResult = [downloader parseURL:@"https://example.com/stream.m3u8"];
    NSLog(@"Parse result: %@", parseResult);
    
    // 下载
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video.mp4"];
    NSDictionary *downloadResult = [downloader downloadURL:@"https://example.com/stream.m3u8" 
                                                   toPath:outputPath];
    NSLog(@"Download result: %@", downloadResult);
}
```

## JSON格式说明

### 配置JSON

```json
{
  "maxConcurrency": 8,
  "timeoutSeconds": 30,
  "retryCount": 3,
  "tempDirectory": "/path/to/temp",
  "autoCleanup": true,
  "customHeaders": {
    "User-Agent": "Custom UA",
    "Authorization": "Bearer token"
  }
}
```

### 下载请求JSON

```json
{
  "url": "https://example.com/playlist.m3u8",
  "outputPath": "/path/to/output.mp4",
  "decryptionKeys": ["kid:key"],
  "customHeaders": {
    "User-Agent": "Custom UA"
  },
  "autoSelectBestQuality": true
}
```

### 解析结果JSON

```json
{
  "success": true,
  "errorMessage": null,
  "streams": [
    {
      "id": "video-1",
      "type": "video",
      "codec": "avc1.640028",
      "bitrate": 5000000,
      "resolution": "1920x1080",
      "language": null,
      "isEncrypted": false
    }
  ]
}
```

### 下载结果JSON

```json
{
  "success": true,
  "outputFile": "/path/to/output.mp4",
  "fileSize": 104857600,
  "duration": 123.45,
  "errorMessage": null
}
```

### 进度状态JSON

```json
{
  "taskId": 1,
  "description": "Downloading segment 10/100",
  "currentValue": 10,
  "maxValue": 100,
  "percentage": 10.0,
  "speed": 1048576,
  "downloadedBytes": 10485760,
  "totalBytes": 104857600
}
```

## 常见问题

### Q: 编译时出现链接错误

确保添加了以下链接器标志：
```
-lc++ -lz -liconv
```

### Q: 运行时崩溃

1. 确保在主线程外调用下载方法
2. 检查内存是否正确释放
3. 确保实例ID有效

### Q: 不支持某些流格式

当前版本支持：
- HLS (M3U8)
- DASH (MPD)
- MSS

### Q: 如何处理加密流？

在下载请求中提供解密密钥：
```json
{
  "decryptionKeys": ["KID:KEY"]
}
```

## 支持

如有问题，请提交 Issue 或联系开发团队。
