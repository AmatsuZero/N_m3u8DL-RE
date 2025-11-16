# iOS Library 集成指南

本文档说明如何将 N_m3u8DL-RE Core 库集成到 iOS 应用中。

## 📦 构建 iOS Library

### 方式一：完整版本（推荐）

构建包含设备和模拟器支持的 XCFramework：

```bash
./build-ios-library.sh
```

输出：`output/N_m3u8DL_RE_Core.xcframework`

### 方式二：简化版本

仅构建设备版本（用于快速测试）：

```bash
./build-ios-library-simple.sh
```

输出：`output/ios-library/*.dylib`

## 🔧 集成到 Xcode 项目

### 步骤 1：添加 XCFramework

1. 打开你的 Xcode 项目
2. 选择项目 Target
3. 进入 "General" 标签页
4. 在 "Frameworks, Libraries, and Embedded Content" 部分点击 "+"
5. 选择 "Add Other..." → "Add Files..."
6. 选择 `N_m3u8DL_RE_Core.xcframework`
7. 确保 "Embed & Sign" 选项已选中

### 步骤 2：配置 Build Settings

1. 进入 "Build Settings" 标签页
2. 搜索 "Framework Search Paths"
3. 添加 XCFramework 所在目录的路径

## 💻 使用示例

### Objective-C 示例

**M3U8Downloader.h**

```objective-c
#import <Foundation/Foundation.h>
#import <N_m3u8DL_RE_Core/N_m3u8DL_RE_Core.h>

@interface M3U8Downloader : NSObject

- (instancetype)init;
- (void)downloadURL:(NSString *)url 
         outputPath:(NSString *)outputPath
         onProgress:(void (^)(int progress))progressBlock
       onCompletion:(void (^)(BOOL success, NSString *output))completionBlock;
- (void)cancel;

@end
```

**M3U8Downloader.m**

```objective-c
#import "M3U8Downloader.h"

@implementation M3U8Downloader {
    dispatch_queue_t _downloadQueue;
    BOOL _isCancelled;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        m3u8dl_init();
        _downloadQueue = dispatch_queue_create("com.m3u8dl.download", DISPATCH_QUEUE_SERIAL);
        _isCancelled = NO;
    }
    return self;
}

- (void)downloadURL:(NSString *)url 
         outputPath:(NSString *)outputPath
         onProgress:(void (^)(int))progressBlock
       onCompletion:(void (^)(BOOL, NSString *))completionBlock {
    
    const char *urlCStr = [url UTF8String];
    const char *pathCStr = [outputPath UTF8String];
    
    dispatch_async(_downloadQueue, ^{
        // 启动下载
        int result = m3u8dl_download(urlCStr, pathCStr, ^(int res, const char* output) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    NSString *outputStr = output ? [NSString stringWithUTF8String:output] : nil;
                    completionBlock(res == 0, outputStr);
                }
            });
        });
        
        if (result != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(NO, nil);
                }
            });
            return;
        }
        
        // 监控进度
        while (!self->_isCancelled) {
            int progress = m3u8dl_get_progress();
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (progressBlock) {
                    progressBlock(progress);
                }
            });
            
            if (progress >= 100) {
                break;
            }
            
            [NSThread sleepForTimeInterval:0.5];
        }
    });
}

- (void)cancel {
    _isCancelled = YES;
    m3u8dl_cancel();
}

- (void)dealloc {
    [self cancel];
}

@end
```

**使用示例**

```objective-c
// 在 ViewController 中使用
M3U8Downloader *downloader = [[M3U8Downloader alloc] init];

[downloader downloadURL:@"https://example.com/playlist.m3u8"
             outputPath:@"/path/to/output.mp4"
             onProgress:^(int progress) {
                 NSLog(@"下载进度: %d%%", progress);
             }
           onCompletion:^(BOOL success, NSString *output) {
               if (success) {
                   NSLog(@"下载完成: %@", output);
               } else {
                   NSLog(@"下载失败");
               }
           }];
```

### Swift 示例

**M3U8Downloader.swift**

```swift
import Foundation

class M3U8Downloader {
    typealias ProgressCallback = @convention(c) (Int32, Int64, Int64) -> Void
    typealias CompletionCallback = @convention(c) (Int32, UnsafePointer<CChar>?) -> Void
    
    private var isCancelled = false
    private let downloadQueue = DispatchQueue(label: "com.m3u8dl.download")
    
    init() {
        m3u8dl_init()
    }
    
    func download(url: String, 
                  outputPath: String,
                  onProgress: @escaping (Int) -> Void,
                  onCompletion: @escaping (Bool, String?) -> Void) {
        
        isCancelled = false
        
        downloadQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 启动下载
            let result = url.withCString { urlPtr in
                outputPath.withCString { pathPtr in
                    m3u8dl_download(urlPtr, pathPtr) { result, outputPtr in
                        DispatchQueue.main.async {
                            let success = result == 0
                            let output = outputPtr != nil ? String(cString: outputPtr!) : nil
                            onCompletion(success, output)
                        }
                    }
                }
            }
            
            if result != 0 {
                DispatchQueue.main.async {
                    onCompletion(false, nil)
                }
                return
            }
            
            // 监控进度
            while !self.isCancelled {
                let progress = Int(m3u8dl_get_progress())
                
                DispatchQueue.main.async {
                    onProgress(progress)
                }
                
                if progress >= 100 {
                    break
                }
                
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    func cancel() {
        isCancelled = true
        m3u8dl_cancel()
    }
    
    deinit {
        cancel()
    }
}
```

**使用示例**

```swift
// 在 ViewController 中使用
let downloader = M3U8Downloader()

downloader.download(
    url: "https://example.com/playlist.m3u8",
    outputPath: "/path/to/output.mp4",
    onProgress: { progress in
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
```

## 📚 API 参考

### 初始化

```c
int m3u8dl_init(void);
```

初始化库，必须在使用其他 API 前调用。

**返回值**：
- `0`：成功
- 负数：错误码

### 下载

```c
int m3u8dl_download(
    const char* url, 
    const char* output_path, 
    m3u8dl_completion_callback callback
);
```

开始下载任务。

**参数**：
- `url`：M3U8 播放列表 URL
- `output_path`：输出文件路径
- `callback`：完成回调函数

**返回值**：
- `0`：成功启动
- `-1`：一般错误
- `-2`：无效的 URL

### 获取进度

```c
int m3u8dl_get_progress(void);
```

获取当前下载进度。

**返回值**：进度百分比 (0-100)

### 取消下载

```c
int m3u8dl_cancel(void);
```

取消当前下载任务。

**返回值**：
- `0`：成功
- 负数：错误码

### 获取版本

```c
const char* m3u8dl_get_version(void);
```

获取库版本信息。

**返回值**：版本字符串

### 获取 API 版本

```c
int m3u8dl_get_api_version(void);
```

获取 API 版本号。

**返回值**：版本号 (MAJOR << 16 | MINOR << 8 | PATCH)

### 释放字符串

```c
void m3u8dl_free_string(const char* str);
```

释放由库分配的字符串内存。

## ⚠️ 注意事项

### 1. 线程安全

- 所有 API 调用都应该在同一个线程中进行
- 建议使用串行队列管理下载任务

### 2. 内存管理

- 由 `m3u8dl_get_version()` 返回的字符串需要调用 `m3u8dl_free_string()` 释放
- 回调函数中的字符串指针仅在回调期间有效

### 3. 错误处理

- 始终检查返回值
- 负数返回值表示错误

### 4. 权限要求

确保在 Info.plist 中添加必要的权限：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 🐛 故障排除

### 问题：找不到 Framework

**解决方案**：
1. 检查 Framework Search Paths 是否正确
2. 确保 XCFramework 已正确添加到项目中
3. 清理构建目录 (Product → Clean Build Folder)

### 问题：运行时崩溃

**解决方案**：
1. 确保已调用 `m3u8dl_init()`
2. 检查传递的参数是否有效
3. 查看控制台日志获取详细错误信息

### 问题：下载失败

**解决方案**：
1. 检查网络连接
2. 验证 URL 是否有效
3. 确保有足够的存储空间
4. 检查文件写入权限

## 📄 许可证

遵循项目原有许可证。

## 🔗 相关链接

- [项目主页](https://github.com/nilaoda/N_m3u8DL-RE)
- [架构文档](../ARCHITECTURE.md)
- [重构说明](../REFACTORING.md)
