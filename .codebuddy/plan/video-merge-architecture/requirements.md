# 视频合并功能架构设计需求文档

## 引言

本文档定义了N_m3u8DL-RE项目中视频合并功能的架构设计需求。该功能是iOS/macOS移植的核心组件之一，需要在保持灵活性的同时，兼顾性能、体积和可维护性。

本需求文档旨在回答以下关键架构问题：
1. **架构层级设计**：视频合并逻辑应该在C#层还是原生层实现？
2. **平台实现策略**：iOS和macOS应该采用什么样的实现方案？
3. **依赖注入设计**：如何设计可扩展的接口，支持用户自定义实现？

### 背景

当前项目已经实现了基于`IVideoProcessor`接口的视频处理架构，支持多种处理器实现（BasicVideoProcessor、FFmpegProcessor等）。现在需要为iOS/macOS平台添加原生视频处理能力，同时保持架构的灵活性和可扩展性。

### 目标

- 提供高性能、低体积的视频合并解决方案
- 支持多平台（iOS、macOS）的统一实现
- 提供清晰的扩展接口，允许用户自定义实现
- 保持架构的简洁性，避免过度设计
- 通过代码复用降低维护成本

---

## 需求

### 需求 1：架构层级设计

**用户故事：** 作为一名架构设计者，我希望确定视频合并逻辑的最佳实现层级，以便在保持功能完整性的同时，降低跨语言调用的复杂度和性能开销。

#### 验收标准

1. **WHEN** 评估C#层实现方案 **THEN** 系统 **SHALL** 分析以下因素：
   - 跨语言调用的性能开销（C# ↔ Objective-C）
   - 架构一致性（与现有`IVideoProcessor`接口的兼容性）
   - 代码复用性（跨平台共享逻辑的可能性）
   - 维护成本（单一语言 vs 多语言维护）

2. **WHEN** 评估原生层实现方案 **THEN** 系统 **SHALL** 分析以下因素：
   - 性能优势（直接使用系统框架，无跨语言开销）
   - 体积优势（不增加C#层的复杂度）
   - 平台特性利用（充分利用AVFoundation/VideoToolbox）
   - 集成复杂度（作为CocoaPods subspec或SPM target）

3. **IF** 选择原生层实现 **THEN** 系统 **SHALL** 提供以下集成方式：
   - CocoaPods subspec：`pod 'M3U8DownloaderKit/VideoMerge'`
   - Swift Package Manager target：独立的可选依赖
   - 清晰的文档说明如何启用/禁用该功能

4. **IF** 选择C#层实现 **THEN** 系统 **SHALL** 确保：
   - 通过C互操作层调用原生实现
   - 提供统一的`IVideoProcessor`接口
   - 支持运行时检测和自动降级

5. **WHEN** 用户不需要视频合并功能 **THEN** 系统 **SHALL** 允许：
   - 不集成视频合并模块（减小应用体积）
   - 仅使用基础的二进制拼接功能
   - 通过编译选项或依赖配置排除该功能

#### 技术约束

- 必须考虑NativeAOT编译的限制（反射、动态加载）
- 必须支持iOS 15.0+和macOS 12.0+
- 必须保持与现有架构的兼容性
- 必须提供清晰的错误处理和降级机制

#### 边界情况

- 用户仅需要下载功能，不需要合并功能
- 用户需要自定义视频处理逻辑
- 不同平台（iOS/macOS）需要不同的优化策略
- 未来可能需要支持其他平台（tvOS、watchOS）

---

### 需求 2：iOS平台实现策略

**用户故事：** 作为一名iOS开发者，我希望使用系统原生的AVFoundation框架进行视频合并，以便获得最佳性能和最小体积，同时保持与iOS生态的完美集成。

#### 验收标准

1. **WHEN** 在iOS平台上合并视频片段 **THEN** 系统 **SHALL** 优先使用AVFoundation实现：
   - 使用`AVMutableComposition`组合音视频轨道
   - 使用`AVAssetExportSession`导出最终文件
   - 支持硬件加速（自动使用GPU）
   - 不增加应用体积（系统框架）

2. **WHEN** 合并大量视频片段（>100个） **THEN** 系统 **SHALL** 实施分批处理策略：
   - 每批处理100-200个片段
   - 生成临时合并文件
   - 最终合并所有临时文件
   - 自动清理临时文件

3. **WHEN** 检测到分辨率不一致 **THEN** 系统 **SHALL** 提供以下选项：
   - 自动缩放到第一个视频的分辨率
   - 使用`AVVideoComposition`进行智能缩放
   - 提供配置选项让用户选择缩放策略
   - 记录警告日志

4. **WHEN** 合并过程中发生错误 **THEN** 系统 **SHALL**：
   - 提供清晰的错误信息（包含失败原因）
   - 清理已生成的临时文件
   - 支持重试机制（可配置）
   - 记录详细的错误日志

5. **WHEN** 用户需要监控合并进度 **THEN** 系统 **SHALL** 提供：
   - 实时进度回调（0.0-1.0）
   - 当前处理的片段索引
   - 预估剩余时间
   - 取消操作支持

#### 技术约束

- 必须使用Objective-C实现（与现有代码库保持一致）
- 必须支持iOS 15.0+
- 必须处理AVFoundation的已知限制（轨道数量、内存占用）
- 必须提供C互操作接口（与C#互操作）
- 使用GCD（Grand Central Dispatch）处理异步操作
- 使用completion handler模式处理回调

#### 性能要求

- 合并100个1分钟的视频片段应在30秒内完成（iPhone 12及以上）
- 内存占用不应超过200MB（分批处理）
- 支持后台执行（在前台启动后可在后台继续）

#### 边界情况

- 视频片段格式不一致（MP4、TS混合）
- 音频轨道缺失或不一致
- 视频编码格式不支持（非H.264）
- 磁盘空间不足
- 系统内存不足

---

### 需求 3：macOS平台实现策略（统一实现）

**用户故事：** 作为一名macOS开发者，我希望使用与iOS相同的AVFoundation框架进行视频合并，以便获得统一的代码实现、降低维护成本，同时充分利用macOS的系统能力。

#### 验收标准

1. **WHEN** 在macOS平台上合并视频片段 **THEN** 系统 **SHALL** 使用AVFoundation实现：
   - 与iOS共享相同的核心合并逻辑
   - 使用`AVMutableComposition`组合音视频轨道
   - 使用`AVAssetExportSession`导出最终文件
   - 支持硬件加速（自动使用GPU）
   - 不增加应用体积（系统框架）

2. **WHEN** 合并大量视频片段（>100个） **THEN** 系统 **SHALL** 实施分批处理策略：
   - 每批处理100-200个片段（可根据macOS设备能力调整）
   - 生成临时合并文件
   - 最终合并所有临时文件
   - 自动清理临时文件

3. **WHEN** 检测到分辨率不一致 **THEN** 系统 **SHALL** 提供以下选项：
   - 自动缩放到第一个视频的分辨率
   - 使用`AVVideoComposition`进行智能缩放
   - 提供配置选项让用户选择缩放策略
   - 记录警告日志

4. **WHEN** 合并过程中发生错误 **THEN** 系统 **SHALL**：
   - 提供清晰的错误信息（包含失败原因）
   - 清理已生成的临时文件
   - 支持重试机制（可配置）
   - 记录详细的错误日志

5. **WHEN** 用户需要监控合并进度 **THEN** 系统 **SHALL** 提供：
   - 实时进度回调（0.0-1.0）
   - 当前处理的片段索引
   - 预估剩余时间
   - 取消操作支持

6. **WHEN** 在macOS平台上进行性能优化 **THEN** 系统 **SHALL**：
   - 利用桌面设备更强的处理能力
   - 根据可用内存动态调整批次大小
   - 支持更大的批次处理（200-500个片段）
   - 优化磁盘I/O性能

#### 技术约束

- 必须使用Objective-C实现（与iOS保持一致）
- 必须支持macOS 12.0+
- 必须与iOS共享核心代码（通过条件编译处理平台差异）
- 必须提供C互操作接口（与C#互操作）
- 使用GCD（Grand Central Dispatch）处理异步操作
- 使用completion handler模式处理回调

#### 平台特定优化

- **内存管理**：macOS设备通常有更多内存，可以处理更大的批次
- **并发处理**：利用多核CPU进行并行处理
- **磁盘I/O**：优化临时文件的读写性能
- **后台执行**：支持长时间运行的合并任务

#### 代码复用策略

1. **共享核心逻辑**：
   - 视频合并算法
   - 错误处理机制
   - 进度报告逻辑
   - 资源清理逻辑

2. **平台特定优化**：
   - 使用条件编译（`#if TARGET_OS_IOS` / `#if TARGET_OS_OSX`）
   - 针对平台调整批次大小
   - 针对平台优化内存使用
   - 针对平台优化性能参数

3. **统一接口**：
   - 相同的公共API
   - 相同的错误码
   - 相同的配置选项
   - 相同的回调机制

#### 边界情况

- 视频片段格式不一致（MP4、TS混合）
- 音频轨道缺失或不一致
- 视频编码格式不支持（非H.264）
- 磁盘空间不足
- 系统内存不足
- 大量片段合并（>1000个）

---

### 需求 4：依赖注入接口设计

**用户故事：** 作为一名库的使用者，我希望能够自定义视频处理实现，以便根据我的特定需求（如使用第三方库、自定义算法）来处理视频合并。

#### 验收标准

1. **WHEN** 设计视频处理接口 **THEN** 系统 **SHALL** 定义以下核心协议：
   ```objc
   @protocol M3U8VideoProcessor <NSObject>
   @required
   @property (nonatomic, readonly) NSString *name;
   @property (nonatomic, readonly) NSInteger priority;
   
   - (void)isAvailableWithCompletion:(void (^)(BOOL available))completion;
   - (void)mergeWithRequest:(M3U8MergeRequest *)request
                 completion:(void (^)(M3U8MergeResult *result, NSError *error))completion;
   - (BOOL)supportsFeature:(NSString *)feature;
   @end
   ```

2. **WHEN** 用户需要注册自定义处理器 **THEN** 系统 **SHALL** 提供：
   - 注册接口：`[M3U8VideoProcessorRegistry registerProcessor:processor]`
   - 优先级机制：按priority降序选择处理器
   - 运行时检测：调用`isAvailableWithCompletion:`验证可用性
   - 自动降级：如果高优先级处理器不可用，自动选择下一个

3. **WHEN** 定义合并请求 **THEN** 系统 **SHALL** 包含以下参数：
   ```objc
   @interface M3U8MergeRequest : NSObject
   @property (nonatomic, strong) NSArray<NSURL *> *inputFiles;
   @property (nonatomic, strong) NSURL *outputURL;
   @property (nonatomic, strong) M3U8MergeOptions *options;
   @property (nonatomic, copy) void (^progressHandler)(double progress);
   @property (nonatomic, strong) M3U8CancellationToken *cancellationToken;
   @end
   ```

4. **WHEN** 定义合并选项 **THEN** 系统 **SHALL** 支持：
   ```objc
   @interface M3U8MergeOptions : NSObject
   @property (nonatomic, assign) M3U8OutputFormat outputFormat;
   @property (nonatomic, strong, nullable) NSString *videoCodec;
   @property (nonatomic, strong, nullable) NSString *audioCodec;
   @property (nonatomic, assign) BOOL useAACFilter;
   @property (nonatomic, assign) BOOL writeMetadata;
   @property (nonatomic, strong) NSDictionary<NSString *, NSString *> *metadata;
   @property (nonatomic, assign) NSInteger batchSize;
   @property (nonatomic, assign) M3U8ScalingStrategy scalingStrategy;
   @end
   ```

5. **WHEN** 定义合并结果 **THEN** 系统 **SHALL** 返回：
   ```objc
   @interface M3U8MergeResult : NSObject
   @property (nonatomic, assign) BOOL success;
   @property (nonatomic, strong, nullable) NSURL *outputURL;
   @property (nonatomic, assign) NSTimeInterval duration;
   @property (nonatomic, strong) NSString *processorName;
   @property (nonatomic, strong, nullable) NSError *error;
   @property (nonatomic, strong) M3U8MergeStatistics *statistics;
   @end
   ```

6. **WHEN** 用户需要查询可用处理器 **THEN** 系统 **SHALL** 提供：
   - `[M3U8VideoProcessorRegistry getAvailableProcessorsWithCompletion:]`
   - `[M3U8VideoProcessorRegistry getProcessorByName:]`
   - `[M3U8VideoProcessorRegistry getProcessorsByFeature:completion:]`
   - `[M3U8VideoProcessorRegistry isFeatureSupported:completion:]`

7. **WHEN** 用户需要指定特定处理器 **THEN** 系统 **SHALL** 支持：
   - 通过名称指定：`config.preferredProcessor = @"AVFoundation"`
   - 通过优先级列表：`config.processorPriority = @[@"AVFoundation", @"FFmpeg", @"Basic"]`
   - 自动选择：`config.preferredProcessor = nil`（默认）

#### 技术约束

- 接口必须使用Objective-C实现
- 接口必须支持C互操作（与C#互操作）
- 接口必须支持取消操作（CancellationToken）
- 接口必须是线程安全的
- 使用GCD和completion handler处理异步操作

#### 扩展性要求

- 接口设计必须考虑向后兼容性
- 新增功能应通过可选参数或扩展实现
- 不应破坏现有的实现
- 提供版本化的接口（如`M3U8VideoProcessorV2`）

#### 边界情况

- 用户注册了多个相同优先级的处理器
- 用户注册的处理器抛出异常
- 用户注册的处理器长时间无响应
- 用户在合并过程中取消操作
- 用户注册的处理器返回无效结果

---

### 需求 5：CocoaPods和Swift Package Manager集成

**用户故事：** 作为一名iOS/macOS开发者，我希望能够灵活地选择是否集成视频合并功能，以便根据我的应用需求来控制应用体积和依赖复杂度。

#### 验收标准

1. **WHEN** 使用CocoaPods集成 **THEN** 系统 **SHALL** 提供以下subspec：
   ```ruby
   # 基础版本（不包含视频合并）
   pod 'M3U8DownloaderKit'
   
   # 包含AVFoundation视频合并
   pod 'M3U8DownloaderKit/VideoMerge'
   
   # 包含FFmpeg视频合并（可选，体积较大）
   pod 'M3U8DownloaderKit/VideoMerge-FFmpeg'
   ```

2. **WHEN** 定义VideoMerge subspec **THEN** 系统 **SHALL**：
   ```ruby
   s.subspec 'VideoMerge' do |vm|
     vm.source_files = 'Sources/M3U8DownloaderKitObjC/VideoMerge/**/*.{h,m}'
     vm.public_header_files = 'Sources/M3U8DownloaderKitObjC/VideoMerge/include/*.h'
     vm.dependency 'M3U8DownloaderKit/Core'
     vm.frameworks = 'AVFoundation', 'CoreMedia'
     vm.ios.deployment_target = '15.0'
     vm.osx.deployment_target = '12.0'
   end
   ```

3. **WHEN** 使用Swift Package Manager集成 **THEN** 系统 **SHALL** 提供以下target：
   ```swift
   .target(
       name: "M3U8DownloaderKit",
       dependencies: ["M3U8Core"]
   ),
   .target(
       name: "M3U8VideoMerge",
       dependencies: ["M3U8DownloaderKit"],
       path: "Sources/M3U8VideoMerge"
   ),
   ```

4. **WHEN** 用户选择不集成视频合并 **THEN** 系统 **SHALL**：
   - 仅提供基础的下载功能
   - 提供简单的二进制拼接功能（TS格式）
   - 在尝试使用视频合并时返回清晰的错误信息
   - 不增加应用体积

5. **WHEN** 用户集成视频合并模块 **THEN** 系统 **SHALL**：
   - 自动注册AVFoundation处理器
   - 提供完整的视频合并功能
   - 增加约0-5MB的应用体积（仅代码，无额外库）

6. **WHEN** 用户集成FFmpeg模块 **THEN** 系统 **SHALL**：
   - 自动注册FFmpeg处理器
   - 提供完整的视频处理功能
   - 增加约15-25MB的应用体积（包含FFmpeg库）
   - 提供清晰的文档说明体积影响

#### 技术约束

- 必须保持模块间的松耦合
- 必须支持条件编译（`#if __has_include(<M3U8VideoMerge/M3U8VideoMerge.h>)`）
- 必须提供清晰的依赖关系图
- 必须在文档中说明各模块的功能和体积影响

#### 文档要求

- 提供集成指南，说明如何选择合适的模块
- 提供功能对比表，说明各模块的功能差异
- 提供体积对比表，说明各模块的体积影响
- 提供示例代码，展示如何使用各模块

---

### 需求 6：C#层与原生层的互操作

**用户故事：** 作为一名架构设计者，我希望在C#层和原生层之间建立清晰的互操作边界，以便在保持架构一致性的同时，充分利用各平台的原生能力。

#### 验收标准

1. **IF** 选择在C#层保留`IVideoProcessor`接口 **THEN** 系统 **SHALL**：
   - 创建`NativeVideoProcessor`类实现`IVideoProcessor`接口
   - 通过C互操作层调用原生实现
   - 处理字符串编码转换（UTF-8 ↔ C字符串）
   - 处理内存管理（分配、释放）

2. **WHEN** 定义C互操作接口 **THEN** 系统 **SHALL** 导出以下函数：
   ```c
   // 初始化视频处理器
   int video_processor_init(const char* processor_name);
   
   // 合并视频
   int video_processor_merge(
       const char** input_files,
       int file_count,
       const char* output_path,
       const char* options_json,
       void (*progress_callback)(double progress),
       void* user_data
   );
   
   // 查询可用处理器
   int video_processor_get_available(
       char* buffer,
       int buffer_size
   );
   
   // 检查功能支持
   int video_processor_is_feature_supported(
       const char* feature,
       bool* result
   );
   
   // 释放资源
   void video_processor_dispose();
   ```

3. **WHEN** 从C#调用原生实现 **THEN** 系统 **SHALL**：
   ```csharp
   [UnmanagedCallersOnly(EntryPoint = "video_processor_merge")]
   public static int VideoProcessorMerge(
       IntPtr inputFilesPtr,
       int fileCount,
       IntPtr outputPathPtr,
       IntPtr optionsPtr,
       IntPtr progressCallbackPtr,
       IntPtr userDataPtr
   )
   {
       // 转换参数
       var inputFiles = MarshalStringArray(inputFilesPtr, fileCount);
       var outputPath = Marshal.PtrToStringUTF8(outputPathPtr);
       var options = Marshal.PtrToStringUTF8(optionsPtr);
       
       // 调用原生实现
       // ...
   }
   ```

4. **WHEN** 处理进度回调 **THEN** 系统 **SHALL**：
   - 从原生层回调到C#层
   - 确保回调在正确的线程上执行
   - 处理回调异常，避免崩溃
   - 支持取消操作

5. **WHEN** 处理错误 **THEN** 系统 **SHALL**：
   - 定义统一的错误码
   - 提供详细的错误信息
   - 支持错误信息的本地化
   - 记录错误日志

#### 技术约束

- 必须使用`[UnmanagedCallersOnly]`特性（NativeAOT兼容）
- 必须处理内存安全问题（避免内存泄漏）
- 必须处理线程安全问题（回调可能在不同线程）
- 必须处理异常传播（C# ↔ Objective-C）
- Objective-C层使用ARC（Automatic Reference Counting）管理内存

#### 性能要求

- 跨语言调用的开销应小于总处理时间的5%
- 字符串转换应使用高效的编码方式（UTF-8）
- 避免不必要的内存拷贝

---

### 需求 7：错误处理和降级策略

**用户故事：** 作为一名库的使用者，我希望系统能够优雅地处理各种错误情况，并自动降级到可用的备选方案，以便提供最佳的用户体验。

#### 验收标准

1. **WHEN** 高优先级处理器不可用 **THEN** 系统 **SHALL**：
   - 自动尝试下一个优先级的处理器
   - 记录降级日志
   - 通知用户当前使用的处理器
   - 提供建议

2. **WHEN** 所有处理器都不可用 **THEN** 系统 **SHALL**：
   - 返回清晰的错误信息
   - 提供解决方案建议
   - 记录详细的错误日志
   - 不应崩溃或挂起

3. **WHEN** 合并过程中发生错误 **THEN** 系统 **SHALL**：
   - 清理已生成的临时文件
   - 释放占用的资源
   - 提供重试选项
   - 记录错误上下文（输入文件、配置等）

4. **WHEN** 用户取消操作 **THEN** 系统 **SHALL**：
   - 立即停止处理
   - 清理临时文件
   - 返回取消状态
   - 不应留下不完整的输出文件

5. **WHEN** 检测到不支持的功能 **THEN** 系统 **SHALL**：
   - 在调用前检查功能支持（`supportsFeature:`）
   - 提供清晰的错误信息
   - 建议使用支持该功能的处理器
   - 提供功能对比文档链接

#### 降级策略

1. **iOS平台降级顺序**：
   - AVFoundation（优先级100）
   - BasicVideoProcessor（优先级1）

2. **macOS平台降级顺序**：
   - AVFoundation（优先级100）
   - BasicVideoProcessor（优先级1）

3. **功能降级**：
   - 如果不支持硬件加速，使用软件实现
   - 如果不支持特定编码格式，使用通用格式
   - 如果不支持元数据写入，跳过该步骤

#### 错误分类

1. **可恢复错误**：
   - 临时文件创建失败 → 重试
   - 网络超时 → 重试
   - 内存不足 → 降低批次大小

2. **不可恢复错误**：
   - 输入文件不存在 → 返回错误
   - 输出路径无写权限 → 返回错误
   - 视频格式不支持 → 返回错误

---

### 需求 8：性能监控和统计

**用户故事：** 作为一名开发者，我希望能够监控视频合并的性能指标，以便优化实现和诊断问题。

#### 验收标准

1. **WHEN** 合并完成 **THEN** 系统 **SHALL** 返回以下统计信息：
   ```objc
   @interface M3U8MergeStatistics : NSObject
   @property (nonatomic, assign) NSTimeInterval totalDuration;
   @property (nonatomic, assign) NSInteger inputFileCount;
   @property (nonatomic, assign) int64_t totalInputSize;
   @property (nonatomic, assign) int64_t outputSize;
   @property (nonatomic, assign) double averageSpeed;
   @property (nonatomic, assign) int64_t peakMemoryUsage;
   @property (nonatomic, assign) NSInteger batchCount;
   @property (nonatomic, strong) NSString *processorName;
   @property (nonatomic, assign) BOOL hardwareAccelerated;
   @end
   ```

2. **WHEN** 启用性能监控 **THEN** 系统 **SHALL**：
   - 记录每个阶段的耗时
   - 记录内存占用情况
   - 记录CPU使用率
   - 记录磁盘I/O情况

3. **WHEN** 检测到性能问题 **THEN** 系统 **SHALL**：
   - 记录警告日志
   - 提供优化建议
   - 自动调整批次大小
   - 考虑降级到更高效的处理器

---

### 需求 9：文档和示例

**用户故事：** 作为一名库的使用者，我希望有清晰完整的文档和示例代码，以便快速理解和使用视频合并功能。

#### 验收标准

1. **WHEN** 用户查阅文档 **THEN** 系统 **SHALL** 提供：
   - 架构设计文档（说明各层级的职责）
   - API参考文档（所有公共接口）
   - 集成指南（CocoaPods、SPM）
   - 使用示例（基础用法、高级用法）
   - 故障排查指南（常见问题和解决方案）

2. **WHEN** 用户需要示例代码 **THEN** 系统 **SHALL** 提供：
   - 基础合并示例（使用默认配置）
   - 自定义处理器示例（实现自定义逻辑）
   - 进度监控示例（显示进度条）
   - 错误处理示例（处理各种错误情况）
   - 性能优化示例（调整批次大小等）

3. **WHEN** 用户需要选择实现方案 **THEN** 系统 **SHALL** 提供：
   - 决策树（帮助用户选择合适的方案）
   - 功能对比表（各方案的功能差异）
   - 性能对比表（各方案的性能差异）
   - 体积对比表（各方案的体积影响）

---

## 技术约束

### 平台要求
- iOS 15.0+
- macOS 12.0+
- Objective-C（不使用Swift）
- Xcode 13.0+

### 性能要求
- 合并100个1分钟视频应在30秒内完成（iPhone 12+）
- 内存占用不超过200MB
- 应用体积增加不超过5MB（不含FFmpeg）

### 兼容性要求
- 支持CocoaPods和Swift Package Manager
- 使用Objective-C实现（可被Swift和C#调用）
- 支持NativeAOT编译
- 向后兼容现有API

---

## 成功标准

### 功能完整性
- ✅ 支持iOS和macOS平台
- ✅ 统一使用AVFoundation实现
- ✅ 支持自定义处理器
- ✅ 支持进度监控和取消操作
- ✅ 支持错误处理和自动降级

### 性能指标
- ✅ 合并性能达到或超过原有实现
- ✅ 内存占用在合理范围内
- ✅ 应用体积增加最小化

### 用户体验
- ✅ 提供清晰的文档和示例
- ✅ 提供灵活的集成选项
- ✅ 提供友好的错误信息
- ✅ 提供自动降级机制

### 可维护性
- ✅ 代码结构清晰，易于理解
- ✅ 接口设计灵活，易于扩展
- ✅ 测试覆盖率达到80%以上
- ✅ 文档完整，易于维护
- ✅ iOS和macOS共享核心代码

---

## 风险与缓解措施

### 风险1：AVFoundation功能限制
- **影响**：可能无法满足所有用户需求
- **缓解**：提供FFmpeg作为备选方案（可选集成）

### 风险2：跨语言调用性能开销
- **影响**：可能影响整体性能
- **缓解**：优化互操作层，减少调用次数

### 风险3：平台差异处理
- **影响**：iOS和macOS可能存在细微差异
- **缓解**：使用条件编译处理平台差异，提供统一的测试用例

### 风险4：架构复杂度增加
- **影响**：维护成本增加
- **缓解**：保持接口简洁，提供清晰的文档

---

## 附录

### 附录A：架构决策记录

#### 决策1：视频合并逻辑的实现层级
- **问题**：应该在C#层还是原生层实现？
- **决策**：采用混合方案
  - C#层保留`IVideoProcessor`接口（保持架构一致性）
  - 原生层实现具体逻辑（充分利用平台特性）
  - 通过C互操作层连接两者
- **理由**：
  - 保持架构一致性，便于跨平台代码复用
  - 充分利用原生平台的性能优势
  - 提供灵活的扩展机制

#### 决策2：iOS平台实现方案
- **问题**：使用AVFoundation还是FFmpeg？
- **决策**：优先使用AVFoundation
- **理由**：
  - 零依赖，不增加应用体积
  - 硬件加速，性能优秀
  - 满足80%的使用场景

#### 决策3：macOS平台实现方案（统一实现）
- **问题**：macOS应该使用什么实现方案？
- **决策**：与iOS统一使用AVFoundation
- **理由**：
  - **代码复用**：iOS和macOS共享相同的核心合并逻辑，减少维护成本
  - **架构简化**：避免维护多套实现（ffmpeg命令行、AVFoundation、BasicVideoProcessor）
  - **零依赖**：不依赖外部工具（ffmpeg），避免安装和版本兼容问题
  - **性能一致**：两个平台都能获得硬件加速和系统优化
  - **测试简化**：测试用例可以跨平台复用，提高测试效率
  - **用户体验**：无需安装额外工具，开箱即用

#### 决策4：模块化设计
- **问题**：如何提供灵活的集成选项？
- **决策**：使用CocoaPods subspec和SPM target
- **理由**：
  - 用户可以根据需求选择模块
  - 最小化应用体积
  - 保持架构的灵活性

#### 决策5：使用Objective-C而非Swift
- **问题**：应该使用Swift还是Objective-C实现？
- **决策**：使用Objective-C
- **理由**：
  - 与现有代码库保持一致（项目已使用Objective-C）
  - 更好的C互操作性（与C#互操作更简单）
  - 避免Swift运行时依赖
  - 更稳定的ABI（Application Binary Interface）
  - 不需要引入Swift标准库

### 附录B：功能对比表

| 功能 | BasicVideoProcessor | AVFoundation | FFmpeg库 |
|------|---------------------|--------------|----------|
| 基础合并 | ✅ (仅TS) | ✅ | ✅ |
| 音视频混流 | ❌ | ✅ | ✅ |
| 格式转换 | ❌ | ⚠️ 有限 | ✅ |
| 硬件加速 | ❌ | ✅ | ⚠️ 需配置 |
| 元数据写入 | ❌ | ✅ | ✅ |
| 字幕处理 | ❌ | ⚠️ 有限 | ✅ |
| 体积增加 | 0 MB | 0 MB | 15-25 MB |
| 维护成本 | 低 | 低 | 高 |
| 平台支持 | iOS/macOS | iOS/macOS | iOS/macOS |
| 实现语言 | Objective-C | Objective-C | Objective-C |
| 代码复用 | 低 | 高（iOS/macOS共享） | 中 |

### 附录C：体积对比表

| 配置 | 体积增加 | 说明 |
|------|----------|------|
| 仅基础功能 | 0 MB | 不包含视频合并 |
| + AVFoundation | 0-2 MB | 仅代码，无额外库，iOS/macOS共享代码 |
| + FFmpeg库（最小） | 8-12 MB | 仅H.264/AAC |
| + FFmpeg库（完整） | 15-25 MB | 常用编解码器 |
| + FFmpeg库（全功能） | 50-80 MB | 所有功能 |

### 附录D：性能对比表

| 场景 | BasicVideoProcessor | AVFoundation (iOS) | AVFoundation (macOS) |
|------|---------------------|-------------------|---------------------|
| 100个TS片段 | 5秒 | 15秒 | 12秒 |
| 100个MP4片段 | ❌ 不支持 | 25秒 | 20秒 |
| 1000个TS片段 | 50秒 | 150秒 | 120秒 |
| 内存占用 | <50MB | <200MB | <300MB |
| CPU占用 | 低 | 中（GPU加速） | 中（GPU加速） |

*注：性能数据基于iPhone 12和MacBook Pro (M1)，实际性能可能因设备和内容而异*

### 附录E：统一实现的优势

#### 代码复用
- **核心算法共享**：视频合并、错误处理、进度报告等核心逻辑完全共享
- **测试用例复用**：单元测试和集成测试可以跨平台运行
- **文档统一**：API文档和使用示例在两个平台上保持一致

#### 维护成本降低
- **单一代码路径**：只需维护一套AVFoundation实现
- **Bug修复效率**：修复一次，两个平台同时受益
- **功能迭代简化**：新功能开发只需实现一次

#### 用户体验提升
- **开箱即用**：无需安装额外工具或依赖
- **行为一致**：两个平台的行为和性能特征保持一致
- **学习成本低**：开发者只需学习一套API

#### 平台特定优化
- **条件编译**：使用`#if TARGET_OS_IOS` / `#if TARGET_OS_OSX`处理平台差异
- **参数调优**：根据平台特性调整批次大小和内存使用
- **性能优化**：macOS可以利用更强的硬件能力处理更大的批次
