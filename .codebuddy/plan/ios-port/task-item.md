# N_m3u8DL-RE iOS移植实施计划

本文档定义了将N_m3u8DL-RE移植到iOS平台的具体实施任务。所有任务都是可执行的编码步骤，按照依赖关系组织。

---

## 阶段一：核心模块重构与分离

- [ ] **1. 创建iOS核心库项目**
   - 创建新的.NET项目 `N_m3u8DL-RE.Core`，目标框架为 `net10.0`
   - 配置项目为类库输出类型（`<OutputType>library</OutputType>`）
   - 移除对UI框架的依赖（不引用Spectre.Console、System.CommandLine）
   - 添加对 `N_m3u8DL-RE.Common` 和 `N_m3u8DL-RE.Parser` 的项目引用
   - _需求：1.2, 1.3_

- [ ] **2. 提取并重构下载管理器**
   - 将 `SimpleDownloadManager` 和 `SimpleDownloader` 类复制到Core项目
   - 移除所有Spectre.Console相关的UI代码（进度条、表格显示等）
   - 将日志输出从 `Logger` 改为抽象的 `ILogger` 接口
   - 实现基于委托的进度回调机制（`Action<DownloadProgress>`）
   - 添加取消令牌支持（`CancellationToken`）
   - _需求：1.2, 1.4, 3.3_

- [ ] **3. 提取流媒体解析器**
   - 将 `StreamExtractor` 及相关Extractor类（HLS、DASH、MSS）移至Core项目
   - 确保解析器不依赖命令行参数，使用配置对象模式
   - 保留 `ParserConfig` 配置类，确保其可序列化
   - 验证HTTP请求功能在iOS上的兼容性（`HTTPUtil`）
   - _需求：1.2, 8.1_

- [ ] **4. 提取加密解密模块**
   - 将 `AESUtil`、`ChaCha20Util` 和 `CSChaCha20` 类移至Core项目
   - 验证 `System.Security.Cryptography` 在iOS上的可用性
   - 移除对外部工具（mp4decrypt）的依赖，优先使用纯C#实现
   - 为不支持的加密方式提供清晰的异常信息
   - _需求：1.2, 9.1, 9.2_

- [ ] **5. 重构文件处理工具（移除外部工具依赖）**
   - 将 `MergeUtil` 移至Core项目，移除对ffmpeg的直接调用
   - 实现纯C#的基础文件合并功能（简单拼接）作为默认实现
   - 修改 `MP4DecryptUtil`，移除 `Process.Start` 调用
   - 使用iOS兼容的路径处理（`Path.Combine`，避免硬编码路径分隔符）
   - _需求：1.2, 2.3, 6.5, 8.2_

---

## 阶段二：灵活架构设计与接口抽象

- [ ] **6. 设计视频处理接口抽象层**
   - 创建 `IVideoProcessor` 接口，定义合并、混流等核心方法
   - 定义 `VideoProcessorType` 枚举（Native、FFmpeg、Simple）
   - 创建 `VideoProcessorOptions` 配置类，包含各处理器的特定选项
   - 定义 `IVideoProcessorDelegate` 协议，用于处理进度和状态回调
   - _需求：13.1, 13.6_

- [ ] **7. 实现基础视频处理器（纯C#实现）**
   - 实现 `SimpleFileProcessor` 类，提供基础文件拼接功能
   - 支持简单的TS分片合并（直接二进制拼接）
   - 支持MP4分片合并（使用fMP4格式特性）
   - 实现进度报告和取消支持
   - _需求：6.3, 13.1_

- [ ] **8. 评估并实现iOS原生视频处理器**
   - 研究VideoToolbox和AVFoundation的视频合并能力
   - 实现 `VideoToolboxProcessor` 类（如果可行）
   - 使用AVAssetExportSession进行音视频混流
   - 比较原生方案与ffmpeg的性能和功能差异
   - 记录原生方案的限制和适用场景
   - _需求：6.2, 13.1_

- [ ] **9. 设计下载策略接口**
   - 创建 `IDownloadStrategy` 接口，定义下载行为
   - 提供默认的 `DefaultDownloadStrategy` 实现
   - 支持通过委托注入自定义HTTP客户端
   - 支持自定义重试策略和错误处理
   - _需求：13.2_

- [ ] **10. 实现视频处理器工厂和策略选择机制**
   - 创建 `VideoProcessorFactory` 类，负责创建处理器实例
   - 实现运行时检测功能，判断各处理器的可用性
   - 实现自动降级机制：Native → FFmpeg → Simple
   - 提供 `GetAvailableProcessors()` 和 `IsFeatureSupported()` 查询方法
   - _需求：13.3, 13.4_

---

## 阶段三：iOS友好的API接口设计

- [ ] **11. 设计公共API接口层**
   - 创建 `M3u8DownloaderConfig` 配置类，包含所有下载选项
   - 添加 `VideoProcessorType` 和 `PreferredProcessors` 属性
   - 创建 `M3u8Downloader` 主类，提供初始化和下载方法
   - 定义 `IDownloadProgressDelegate` 委托协议，用于进度回调
   - 定义 `DownloadError` 错误枚举和 `DownloadException` 异常类
   - 创建 `StreamInfo` 和 `MediaTrack` 数据模型类
   - 确保所有公共类型使用简单数据类型（避免复杂泛型、元组）
   - _需求：3.1, 3.2, 3.4, 13.5_

- [ ] **12. 实现异步下载接口**
   - 在 `M3u8Downloader` 中实现 `StartDownloadAsync` 方法
   - 实现 `ParseStreamAsync` 方法，返回可用的流信息
   - 添加 `CancelDownload` 方法，支持取消操作
   - 实现进度回调机制，定期触发 `IDownloadProgressDelegate` 回调
   - 添加完成、错误、取消等状态的回调方法
   - 集成视频处理器工厂，根据配置选择合适的处理器
   - _需求：3.3, 3.4, 13.3_

- [ ] **13. 实现日志接口抽象**
   - 创建 `ILogger` 接口，定义 `Log(LogLevel, string)` 方法
   - 在Core项目中使用 `ILogger` 替代所有 `Logger` 静态调用
   - 在 `M3u8DownloaderConfig` 中添加 `Logger` 属性，允许注入自定义日志实现
   - 提供默认的空日志实现（`NullLogger`）
   - _需求：1.5, 3.5_

---

## 阶段四：NativeAOT编译配置

- [ ] **14. 配置iOS平台的AOT编译**
   - 在Core项目的csproj中添加 `<RuntimeIdentifier>ios-arm64</RuntimeIdentifier>`
   - 启用 `<PublishAot>true</PublishAot>` 和 `<PublishTrimmed>true</PublishTrimmed>`
   - 添加 `<IlcOptimizationPreference>Speed</IlcOptimizationPreference>`
   - 配置 `<IlcGenerateStackTraceData>false</IlcGenerateStackTraceData>` 以减小体积
   - 添加条件编译符号 `<DefineConstants>IOS</DefineConstants>`
   - _需求：4.1_

- [ ] **15. 处理反射和动态代码**
   - 识别所有使用反射的代码（JSON序列化、动态类型加载）
   - 为JSON序列化添加Source Generator支持（`System.Text.Json.SourceGeneration`）
   - 创建 `JsonSerializerContext` 类，标记所有需要序列化的类型
   - 移除或替换动态类型加载代码
   - 添加 `[DynamicallyAccessedMembers]` 特性标记必要的类型
   - _需求：4.2_

- [ ] **16. 配置链接器保留规则**
   - 创建 `IlcArg.txt` 文件，配置链接器选项
   - 添加 `rd.xml` 文件，标记需要保留的类型和方法
   - 保留所有公共API类型和方法
   - 保留加密相关的类型（AES、ChaCha20）
   - 保留视频处理器接口和实现类
   - 测试AOT编译，确保没有运行时错误
   - _需求：4.3_

---

## 阶段五：C互操作层与XCFramework打包

- [ ] **17. 创建C风格的导出接口**
   - 创建 `NativeExports` 类，使用 `[UnmanagedCallersOnly]` 特性
   - 导出C风格的初始化函数：`m3u8dl_init`
   - 导出下载函数：`m3u8dl_start_download`
   - 导出取消函数：`m3u8dl_cancel_download`
   - 导出释放资源函数：`m3u8dl_dispose`
   - 导出查询功能：`m3u8dl_get_available_processors`、`m3u8dl_is_feature_supported`
   - 处理字符串编码转换（UTF-8 <-> C字符串）
   - 实现内存管理函数（分配、释放）
   - _需求：5.2, 13.4_

- [ ] **18. 生成C头文件和模块映射**
   - 创建 `m3u8dl.h` 头文件，声明所有导出的C函数
   - 定义C结构体，对应C#的数据模型
   - 定义 `VideoProcessorType` 枚举
   - 创建 `module.modulemap` 文件，定义模块映射
   - 添加必要的类型定义和枚举
   - _需求：5.2, 5.3_

- [ ] **19. 编译多架构二进制文件（不含ffmpeg）**
   - 配置构建脚本，编译 `ios-arm64`（真机）版本
   - 配置构建脚本，编译 `iossimulator-arm64`（模拟器）版本
   - 使用 `dotnet publish` 命令生成静态库
   - 验证生成的 `.a` 文件包含所有必要的符号
   - 确保不包含ffmpeg依赖，保持体积最小
   - _需求：5.1_

- [ ] **20. 打包基础XCFramework（不含ffmpeg）**
   - 创建构建脚本 `build-xcframework.sh`
   - 使用 `xcodebuild -create-xcframework` 命令打包
   - 包含真机和模拟器的二进制文件
   - 包含公共头文件和模块映射文件
   - 验证XCFramework的结构和完整性
   - _需求：5.3_

---

## 阶段六：Swift绑定层与示例应用

- [ ] **21. 创建Swift包装层**
   - 创建Swift Package项目 `M3u8DownloaderKit`
   - 封装C API为Swift类：`M3u8Downloader`、`DownloadConfig`
   - 实现Swift风格的错误处理（`throws`、`Result`）
   - 实现委托协议：`M3u8DownloaderDelegate`
   - 封装 `VideoProcessorType` 枚举和查询方法
   - 提供类型安全的枚举和结构体
   - 添加便利初始化方法和属性
   - _需求：5.4, 13.4_

- [ ] **22. 创建iOS示例应用**
   - 使用Xcode创建iOS示例项目
   - 集成XCFramework和Swift包装层
   - 实现基本UI：URL输入、下载按钮、进度显示
   - 添加视频处理器选择界面（Native/Simple）
   - 实现下载功能演示：HLS流下载
   - 实现进度回调和错误处理
   - 添加日志输出功能
   - 显示当前使用的视频处理器类型
   - _需求：10.5, 13.3_

---

## 阶段七：测试与文档

- [ ] **23. 编写单元测试**
   - 为Core项目创建测试项目 `N_m3u8DL-RE.Core.Tests`
   - 编写流媒体解析器测试（HLS、DASH）
   - 编写加密解密功能测试（AES、ChaCha20）
   - 编写文件处理工具测试
   - 编写下载管理器测试（使用Mock）
   - 测试视频处理器工厂和策略选择逻辑
   - 确保所有测试在iOS模拟器上通过
   - _需求：10.1_

- [ ] **24. 编写集成测试**
   - 创建集成测试项目，测试完整下载流程
   - 测试HLS点播流下载（使用不同的视频处理器）
   - 测试DASH点播流下载
   - 测试加密流下载
   - 测试错误处理和取消操作
   - 测试自动降级机制
   - 在真机和模拟器上运行测试
   - _需求：10.2, 10.3, 13.3_

- [ ] **25. 编写文档和集成指南**
   - 编写架构文档，说明模块划分和职责
   - 编写视频处理器架构文档，说明接口设计和扩展方式
   - 编写API参考文档，包含所有公共接口
   - 编写集成指南：XCFramework导入步骤
   - 编写使用示例：基本下载、进度监控、错误处理、视频处理器选择
   - 编写扩展指南：如何实现自定义视频处理器
   - 编写故障排查指南，记录常见问题
   - 创建README文件，包含快速开始指南
   - _需求：11.1, 11.2, 11.3, 11.4, 11.5, 13.7_

---

## 阶段八：ffmpeg集成方案（可选）

- [ ] **26. 评估ffmpeg集成方案**
   - 研究FFmpeg.AutoGen在iOS上的可用性
   - 评估mobile-ffmpeg/ffmpeg-kit的集成复杂度和体积影响
   - 分析主流iOS项目（VLC、ijkplayer）的ffmpeg集成方式
   - 测试ffmpeg-kit的基本功能（合并、混流）
   - 记录ffmpeg集成的优势和劣势
   - _需求：6.3_

- [ ] **27. 实现FFmpeg视频处理器（如果可行）**
   - 创建 `FFmpegProcessor` 类，实现 `IVideoProcessor` 接口
   - 使用ffmpeg-kit或FFmpeg.AutoGen进行视频合并
   - 实现音视频混流功能
   - 实现进度报告和取消支持
   - 处理ffmpeg错误和异常
   - _需求：6.3, 13.1_

- [ ] **28. 编译包含ffmpeg的XCFramework（可选）**
   - 配置构建脚本，链接ffmpeg库
   - 编译包含ffmpeg的多架构二进制文件
   - 控制ffmpeg库体积（仅包含必要的编解码器）
   - 打包为独立的XCFramework（如 `M3u8DownloaderKit-FFmpeg`）
   - 提供配置选项让调用方选择是否使用ffmpeg版本
   - _需求：6.7, 13.5_

- [ ] **29. 更新文档说明ffmpeg集成**
   - 编写ffmpeg集成指南
   - 说明如何选择基础版本或ffmpeg版本
   - 比较两个版本的功能差异和体积差异
   - 提供ffmpeg版本的使用示例
   - _需求：6.3, 11.3_

---

## 阶段九：WebAssembly备选方案（可选）

- [ ] **30. WebAssembly方案原型**
   - 配置Core项目支持WASM编译（`<RuntimeIdentifier>browser-wasm</RuntimeIdentifier>`）
   - 创建JavaScript桥接层
   - 实现Swift与JavaScript的互操作
   - 测试WASM方案的性能表现
   - 编写WASM方案的可行性报告
   - _需求：7.1, 7.2, 7.3, 7.4_

---

## 注意事项

- 每个任务完成后，应进行代码审查和测试
- 优先完成阶段一至阶段七的任务，阶段八和阶段九为可选任务
- 阶段二的架构设计是核心，确保接口设计足够灵活和可扩展
- 默认提供不含ffmpeg的基础版本，保持体积最小
- ffmpeg集成作为可选功能，提供独立的XCFramework
- 遇到技术障碍时，及时记录并寻求替代方案
- 保持与原项目的功能一致性，避免引入破坏性变更

## 实施优先级

1. **高优先级**（必须完成）：阶段一至阶段七
2. **中优先级**（建议完成）：阶段八（ffmpeg集成）
3. **低优先级**（研究性质）：阶段九（WASM方案）

## 架构设计原则

1. **接口优先**：先设计接口，再实现具体功能
2. **策略模式**：使用策略模式支持多种视频处理实现
3. **依赖注入**：通过依赖注入提供灵活性
4. **开闭原则**：对扩展开放，对修改封闭
5. **最小依赖**：默认版本不依赖外部库，保持体积最小
6. **渐进增强**：提供基础功能，通过可选依赖增强功能
