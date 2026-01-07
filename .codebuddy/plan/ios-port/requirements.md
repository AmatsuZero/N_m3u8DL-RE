# N_m3u8DL-RE iOS移植需求文档

## 引言

本文档定义了将N_m3u8DL-RE（一个跨平台的DASH/HLS/MSS流媒体下载工具）移植到iOS平台的需求。该项目当前是一个基于.NET 10.0的C#命令行应用程序，支持点播和直播流的下载。移植工作的目标是将核心业务逻辑封装为可在iOS应用中调用的框架，同时保持原有功能的完整性。

项目当前架构包含三个主要模块：
- **N_m3u8DL-RE**：命令行前端和下载管理器
- **N_m3u8DL-RE.Parser**：流媒体解析器（支持DASH/HLS/MSS）
- **N_m3u8DL-RE.Common**：公共实体和工具类

主要技术栈：
- 目标框架：.NET 10.0
- 主要依赖：System.CommandLine、Spectre.Console
- 核心功能：流媒体解析、分片下载、加密解密、合并混流

## 需求

### 需求 1：核心业务逻辑模块化重构

**用户故事：** 作为iOS开发者，我希望核心下载和解析逻辑与命令行界面完全分离，以便能够在iOS应用中集成这些功能。

#### 验收标准

1. WHEN 分析现有代码结构 THEN 系统 SHALL 识别出所有与命令行UI相关的代码（CommandLine、Column、Spectre.Console依赖）
2. WHEN 提取核心业务逻辑 THEN 系统 SHALL 创建独立的核心库模块，包含以下功能：
   - 流媒体解析（StreamExtractor及相关Extractor）
   - 下载管理（DownloadManager、Downloader）
   - 加密解密（Crypto模块）
   - 文件处理（Util模块中的MergeUtil、MP4DecryptUtil等）
3. WHEN 重构依赖关系 THEN 系统 SHALL 确保核心模块不依赖任何UI框架（移除Spectre.Console依赖）
4. WHEN 设计API接口 THEN 系统 SHALL 定义清晰的公共接口，支持：
   - 流媒体URL解析
   - 下载任务配置和启动
   - 进度回调和状态通知
   - 错误处理和日志输出
5. IF 核心模块需要日志输出 THEN 系统 SHALL 使用抽象的日志接口，而非直接依赖Console输出

### 需求 2：iOS平台兼容性评估与适配

**用户故事：** 作为技术架构师，我需要评估现有代码和依赖库在iOS平台上的兼容性，以便制定合理的移植策略。

#### 验收标准

1. WHEN 评估.NET运行时支持 THEN 系统 SHALL 确认.NET 10.0是否支持iOS平台的AOT编译
2. WHEN 检查第三方依赖 THEN 系统 SHALL 验证以下依赖的iOS兼容性：
   - Spectre.Console（仅命令行模块使用，核心模块应移除）
   - System.CommandLine（仅命令行模块使用）
   - 标准库中的网络、加密、文件IO相关API
3. WHEN 识别平台特定代码 THEN 系统 SHALL 标记所有使用平台特定API的代码：
   - 文件系统操作（路径、权限）
   - 进程调用（ffmpeg、mp4decrypt等外部工具）
   - 网络代理配置
4. WHEN 评估外部工具依赖 THEN 系统 SHALL 分析以下工具的iOS可用性：
   - ffmpeg（用于合并和混流）
   - mp4decrypt/shaka-packager（用于解密）
   - mkvmerge（用于MKV容器混流）
5. IF 外部工具不可用 THEN 系统 SHALL 提供替代方案或纯C#实现

### 需求 3：iOS友好的API接口设计

**用户故事：** 作为iOS应用开发者，我希望有一套符合iOS开发规范的API接口，以便能够方便地在Swift或Objective-C项目中调用。

#### 验收标准

1. WHEN 设计公共API THEN 系统 SHALL 创建iOS友好的接口层，包含：
   - 初始化和配置类
   - 下载任务管理类
   - 回调和委托协议
2. WHEN 定义数据模型 THEN 系统 SHALL 确保所有公共类型可以正确映射到Swift/Objective-C：
   - 使用简单的数据类型（避免复杂泛型）
   - 提供清晰的属性和方法命名
   - 支持可选值的正确表示
3. WHEN 实现异步操作 THEN 系统 SHALL 提供iOS平台常用的异步模式：
   - 基于委托的回调
   - 进度报告接口
   - 取消操作支持
4. WHEN 处理错误 THEN 系统 SHALL 定义清晰的错误类型和错误码，便于iOS端处理
5. WHEN 提供日志接口 THEN 系统 SHALL 允许iOS应用注入自定义日志处理器
6. IF 需要配置选项 THEN 系统 SHALL 使用配置对象模式，而非大量独立参数

### 需求 4：NativeAOT编译配置

**用户故事：** 作为构建工程师，我需要配置项目以支持NativeAOT编译，以便生成可在iOS设备上运行的原生代码。

#### 验收标准

1. WHEN 配置项目文件 THEN 系统 SHALL 在csproj中添加iOS平台的AOT编译设置：
   - 设置RuntimeIdentifier为ios-arm64
   - 启用PublishAot选项
   - 配置必要的链接器选项
2. WHEN 处理反射代码 THEN 系统 SHALL 识别并修复所有依赖反射的代码：
   - JSON序列化/反序列化
   - 动态类型加载
   - 使用Source Generator替代运行时反射
3. WHEN 配置链接器 THEN 系统 SHALL 确保必要的类型和方法不被裁剪：
   - 创建链接器配置文件
   - 标记需要保留的类型
4. WHEN 处理P/Invoke THEN 系统 SHALL 确保所有本地互操作调用在iOS上可用
5. IF 存在不兼容的代码 THEN 系统 SHALL 提供条件编译的替代实现

### 需求 5：XCFramework打包与分发

**用户故事：** 作为iOS开发者，我希望获得标准的XCFramework格式的库文件，以便能够轻松集成到Xcode项目中。

#### 验收标准

1. WHEN 编译iOS库 THEN 系统 SHALL 生成支持多架构的二进制文件：
   - arm64（真机）
   - arm64-simulator（模拟器）
2. WHEN 创建C互操作层 THEN 系统 SHALL 导出C风格的API接口：
   - 使用UnmanagedCallersOnly特性
   - 定义清晰的C头文件
   - 处理字符串和内存管理
3. WHEN 打包XCFramework THEN 系统 SHALL 使用xcodebuild命令创建标准框架：
   - 包含所有必要的架构
   - 包含公共头文件
   - 包含模块映射文件
4. WHEN 提供Swift绑定 THEN 系统 SHALL 创建Swift友好的包装层：
   - 封装C API为Swift类和方法
   - 提供类型安全的接口
   - 实现Swift风格的错误处理
5. WHEN 编写集成文档 THEN 系统 SHALL 提供详细的集成指南：
   - XCFramework导入步骤
   - 基本使用示例
   - API参考文档

### 需求 6：外部工具依赖处理策略（重点更新）

**用户故事：** 作为系统架构师，我需要制定合理的ffmpeg等外部工具使用策略，优先评估iOS原生方案，并设计灵活的架构以支持多种实现方式。

#### 验收标准

1. WHEN 分析ffmpeg使用场景 THEN 系统 SHALL 详细梳理项目中ffmpeg的具体功能依赖：
   - 视频/音频合并（多个分片合并为单个文件）
   - 格式转换和混流（音视频流混合）
   - 解密功能（如果使用ffmpeg进行解密）
   - 其他高级处理功能
   - 标记哪些功能是核心必需的，哪些可以降级或替代

2. WHEN 评估iOS原生替代方案 THEN 系统 SHALL 优先研究VideoToolbox框架的可行性：
   - 评估VideoToolbox是否能满足视频合并需求
   - 评估AVFoundation是否能满足音视频混流需求
   - 比较原生方案与ffmpeg在性能、功能覆盖度和实现复杂度方面的差异
   - 记录原生方案的优势（系统集成度高、无额外依赖）和限制（功能可能不如ffmpeg全面）

3. WHEN 调研成熟的ffmpeg集成方案 THEN 系统 SHALL 评估以下选项：
   - **FFmpeg.AutoGen**：.NET的ffmpeg绑定库，评估其iOS兼容性
   - **mobile-ffmpeg/ffmpeg-kit**：专为移动平台优化的ffmpeg框架，评估集成复杂度和体积影响
   - **预编译静态库**：通过CocoaPods或Swift Package Manager集成预编译的ffmpeg库
   - 分析主流开源iOS项目如何解决类似问题（如VLC、ijkplayer等）

4. WHEN 评估iOS平台限制 THEN 系统 SHALL 确认以下约束：
   - iOS不支持执行外部进程（Process.Start不可用）
   - 必须使用库形式集成（静态库或动态框架）
   - 沙盒文件访问限制
   - 应用体积和内存限制

5. WHEN 处理其他外部工具 THEN 系统 SHALL 制定替代策略：
   - **mp4decrypt/shaka-packager**：优先使用.NET内置的System.Security.Cryptography实现AES解密
   - **mkvmerge**：评估是否可以使用纯C#实现或iOS原生API替代
   - 为无法实现的功能提供清晰的功能降级或禁用机制

6. WHEN 确定最终方案 THEN 系统 SHALL 遵循以下优先级：
   - **第一优先级**：使用iOS原生API（VideoToolbox、AVFoundation）实现核心功能
   - **第二优先级**：使用成熟的ffmpeg集成方案（如ffmpeg-kit）处理原生API无法覆盖的场景
   - **第三优先级**：实现纯C#的基础功能（如简单文件拼接）作为降级方案
   - **最后选择**：对于无法实现的高级功能，提供清晰的错误提示和文档说明

7. IF 集成ffmpeg THEN 系统 SHALL 确保：
   - 正确链接ffmpeg库到XCFramework
   - 处理多架构支持（真机和模拟器）
   - 控制库体积（仅包含必要的编解码器和功能）
   - 提供配置选项让调用方选择是否启用ffmpeg功能

### 需求 7：WebAssembly备选方案评估

**用户故事：** 作为技术决策者，我需要评估通过WebAssembly实现iOS移植的可行性，以便在直接移植遇到障碍时有备选方案。

#### 验收标准

1. WHEN 评估WASM可行性 THEN 系统 SHALL 分析以下方面：
   - .NET对WASM的支持程度（Blazor WebAssembly）
   - WASM在iOS WebView中的性能表现
   - 文件系统和网络访问能力
2. WHEN 设计WASM架构 THEN 系统 SHALL 定义以下组件：
   - C#核心逻辑编译为WASM模块
   - JavaScript桥接层
   - Swift/Objective-C与JavaScript的互操作
3. WHEN 评估性能影响 THEN 系统 SHALL 测试关键场景：
   - 大文件下载和处理
   - 加密解密性能
   - 内存使用情况
4. WHEN 比较两种方案 THEN 系统 SHALL 提供决策矩阵：
   - 开发复杂度
   - 性能表现
   - 功能完整性
   - 维护成本
5. IF WASM方案可行 THEN 系统 SHALL 提供WASM实现的原型和集成指南
6. IF WASM方案不可行 THEN 系统 SHALL 记录具体的技术限制和原因

### 需求 8：网络和文件IO适配

**用户故事：** 作为核心功能开发者，我需要确保网络下载和文件操作在iOS平台上正常工作，以便核心功能不受影响。

#### 验收标准

1. WHEN 处理HTTP请求 THEN 系统 SHALL 确保HttpClient在iOS上正确工作：
   - 支持自定义请求头
   - 支持代理配置
   - 支持超时设置
2. WHEN 处理文件路径 THEN 系统 SHALL 使用iOS兼容的路径处理：
   - 使用应用沙盒目录
   - 正确处理临时文件
   - 支持文档目录访问
3. WHEN 实现并发下载 THEN 系统 SHALL 确保线程安全和资源管理：
   - 合理控制并发数
   - 正确处理取消操作
   - 避免内存泄漏
4. WHEN 处理大文件 THEN 系统 SHALL 优化内存使用：
   - 使用流式处理
   - 分块读写
   - 及时释放资源
5. IF 需要后台下载 THEN 系统 SHALL 提供与iOS后台传输服务集成的接口

### 需求 9：加密解密功能移植

**用户故事：** 作为安全功能开发者，我需要确保所有加密解密功能在iOS平台上正确实现，以便支持加密流媒体的下载。

#### 验收标准

1. WHEN 实现AES解密 THEN 系统 SHALL 使用.NET标准加密API：
   - 支持AES-128-CBC
   - 支持AES-128-ECB
   - 支持自定义IV和密钥
2. WHEN 实现ChaCha20解密 THEN 系统 SHALL 确保现有C#实现在iOS上可用
3. WHEN 处理密钥管理 THEN 系统 SHALL 提供安全的密钥存储和传递机制
4. WHEN 支持DRM内容 THEN 系统 SHALL 评估iOS平台的DRM支持：
   - FairPlay集成可能性
   - Widevine/PlayReady的限制
5. IF 需要硬件加速 THEN 系统 SHALL 利用iOS平台的加密硬件加速能力

### 需求 10：测试和验证策略

**用户故事：** 作为质量保证工程师，我需要全面的测试策略来验证iOS移植的正确性和稳定性。

#### 验收标准

1. WHEN 创建单元测试 THEN 系统 SHALL 为核心功能编写单元测试：
   - 流媒体解析逻辑
   - 加密解密功能
   - 文件处理工具
2. WHEN 创建集成测试 THEN 系统 SHALL 测试完整的下载流程：
   - HLS点播下载
   - DASH点播下载
   - 直播流录制
3. WHEN 在iOS设备测试 THEN 系统 SHALL 验证以下场景：
   - 真机运行
   - 模拟器运行
   - 不同iOS版本兼容性
4. WHEN 性能测试 THEN 系统 SHALL 测量关键指标：
   - 下载速度
   - 内存占用
   - CPU使用率
   - 电池消耗
5. WHEN 创建示例应用 THEN 系统 SHALL 提供完整的iOS示例项目：
   - Swift实现
   - 基本UI界面
   - 常见使用场景演示

### 需求 11：文档和开发者支持

**用户故事：** 作为第三方开发者，我需要完整的文档和示例代码，以便能够快速集成和使用iOS版本的库。

#### 验收标准

1. WHEN 编写架构文档 THEN 系统 SHALL 提供详细的架构说明：
   - 模块划分和职责
   - 核心类和接口说明
   - 数据流和调用流程
2. WHEN 编写API文档 THEN 系统 SHALL 为所有公共接口提供文档：
   - 方法和属性说明
   - 参数和返回值描述
   - 使用示例
3. WHEN 编写集成指南 THEN 系统 SHALL 提供分步骤的集成教程：
   - 项目配置
   - 依赖添加
   - 基本使用
   - 高级功能
4. WHEN 提供示例代码 THEN 系统 SHALL 包含常见场景的示例：
   - 简单下载
   - 进度监控
   - 错误处理
   - 高级配置
5. WHEN 编写故障排查指南 THEN 系统 SHALL 记录常见问题和解决方案

### 需求 12：构建和发布流程

**用户故事：** 作为DevOps工程师，我需要自动化的构建和发布流程，以便能够持续交付iOS版本的库。

#### 验收标准

1. WHEN 配置CI/CD THEN 系统 SHALL 创建自动化构建流程：
   - 编译.NET项目
   - 运行单元测试
   - 生成XCFramework
   - 打包发布产物
2. WHEN 版本管理 THEN 系统 SHALL 遵循语义化版本规范：
   - 主版本号变更
   - 次版本号变更
   - 补丁版本号变更
3. WHEN 发布产物 THEN 系统 SHALL 提供以下内容：
   - XCFramework文件
   - Swift Package Manager支持
   - CocoaPods支持（可选）
   - 发布说明
4. WHEN 更新文档 THEN 系统 SHALL 同步更新所有相关文档
5. IF 存在破坏性变更 THEN 系统 SHALL 提供迁移指南

### 需求 13：灵活的架构设计（新增）

**用户故事：** 作为系统架构师，我需要设计灵活的架构，通过接口抽象和策略模式支持多种实现方式，以便调用方可以根据需求选择不同的处理策略。

#### 验收标准

1. WHEN 设计视频处理接口 THEN 系统 SHALL 创建统一的抽象层：
   - 定义 `IVideoProcessor` 接口，包含合并、混流等核心方法
   - 提供多种实现：`VideoToolboxProcessor`（iOS原生）、`FFmpegProcessor`（ffmpeg）、`SimpleFileProcessor`（纯C#拼接）
   - 使用工厂模式或依赖注入允许调用方选择具体实现
   - 确保接口设计足够通用，便于未来扩展新的处理器

2. WHEN 设计下载模块 THEN 系统 SHALL 提供灵活的扩展机制：
   - 提供默认的下载实现作为基础功能
   - 定义 `IDownloadStrategy` 接口，允许调用方自定义下载逻辑
   - 支持通过委托或回调机制注入自定义行为（如自定义HTTP客户端、重试策略等）
   - 提供配置选项控制并发数、超时时间、缓冲区大小等参数

3. WHEN 实现策略选择机制 THEN 系统 SHALL 提供以下功能：
   - 在 `M3u8DownloaderConfig` 中添加 `VideoProcessorType` 枚举，允许选择处理器类型
   - 提供 `PreferredProcessor` 属性，支持优先级列表（如：先尝试VideoToolbox，失败则降级到FFmpeg）
   - 实现自动降级机制：当首选方案不可用时，自动切换到备选方案
   - 提供回调接口通知调用方当前使用的处理器类型

4. WHEN 处理功能可用性 THEN 系统 SHALL 提供查询接口：
   - 提供 `GetAvailableProcessors()` 方法，返回当前环境支持的处理器列表
   - 提供 `IsFeatureSupported(feature)` 方法，查询特定功能是否可用
   - 在运行时检测依赖库的可用性（如ffmpeg是否已链接）
   - 提供清晰的错误信息，说明功能不可用的原因和建议的替代方案

5. WHEN 设计配置接口 THEN 系统 SHALL 支持细粒度控制：
   - 允许调用方指定是否启用ffmpeg功能（减小体积）
   - 提供 `VideoProcessorOptions` 配置类，包含各处理器的特定选项
   - 支持运行时切换处理器（在不同任务中使用不同策略）
   - 提供性能和质量的平衡选项（如快速模式vs高质量模式）

6. WHEN 实现代理模式 THEN 系统 SHALL 允许调用方参与处理流程：
   - 定义 `IVideoProcessorDelegate` 协议，包含处理前后的回调方法
   - 允许调用方在处理前修改参数或取消操作
   - 提供进度回调，报告处理进度
   - 支持调用方提供自定义的临时文件路径或输出路径

7. IF 需要扩展新功能 THEN 系统 SHALL 确保架构的可扩展性：
   - 使用开闭原则：对扩展开放，对修改封闭
   - 提供插件机制，允许第三方实现自定义处理器
   - 文档中提供扩展指南和示例代码
   - 保持向后兼容性，避免破坏现有集成

## 技术约束

1. **平台限制**：iOS不支持执行外部进程，所有功能必须通过库调用实现
2. **沙盒限制**：文件访问受iOS沙盒限制，需要使用标准的应用目录
3. **内存限制**：iOS对应用内存使用有严格限制，需要优化大文件处理
4. **后台限制**：后台任务执行时间有限，长时间下载需要特殊处理
5. **AOT编译**：NativeAOT不支持某些.NET特性（如动态代码生成），需要提前处理
6. **体积限制**：集成ffmpeg会显著增加应用体积，需要提供可选配置

## 成功标准

1. 核心下载功能在iOS上完全可用
2. 性能达到原命令行工具的80%以上
3. 提供完整的Swift API和示例应用
4. 通过所有单元测试和集成测试
5. 文档完整，第三方开发者可以独立集成
6. 架构灵活，支持多种视频处理策略
7. 提供清晰的功能可用性查询和降级机制
