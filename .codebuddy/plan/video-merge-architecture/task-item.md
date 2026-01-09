# 视频合并功能实施计划

本文档定义了视频合并功能的实施任务清单。所有任务都基于[需求文档](./requirements.md)，按照依赖关系和优先级排序。

---

## 实施任务清单

### 第一阶段：核心架构和接口定义

- [ ] **1. 创建Objective-C核心接口和数据模型**
  - 定义`M3U8VideoProcessor`协议，包含name、priority、isAvailable、merge、supportsFeature方法
  - 实现`M3U8MergeRequest`类，包含inputFiles、outputURL、options、progressHandler、cancellationToken属性
  - 实现`M3U8MergeOptions`类，包含outputFormat、videoCodec、audioCodec、batchSize、scalingStrategy等配置选项
  - 实现`M3U8MergeResult`类，包含success、outputURL、duration、processorName、statistics等结果信息
  - 实现`M3U8MergeStatistics`类，包含性能统计信息
  - 实现`M3U8CancellationToken`类，支持取消操作
  - 创建公共头文件，导出所有公共接口
  - _需求：4.1, 4.3, 4.4, 4.5, 8.1_

- [ ] **2. 实现视频处理器注册表（Registry）**
  - 实现`M3U8VideoProcessorRegistry`单例类
  - 实现处理器注册方法：`registerProcessor:`
  - 实现处理器查询方法：`getAvailableProcessorsWithCompletion:`、`getProcessorByName:`、`getProcessorsByFeature:completion:`
  - 实现功能支持查询：`isFeatureSupported:completion:`
  - 实现优先级排序逻辑（按priority降序）
  - 实现线程安全机制（使用GCD串行队列）
  - _需求：4.2, 4.6, 4.7_

### 第二阶段：AVFoundation视频合并实现

- [ ] **3. 实现AVFoundation视频处理器核心类**
  - 创建`M3U8AVFoundationProcessor`类，实现`M3U8VideoProcessor`协议
  - 实现`name`属性返回"AVFoundation"
  - 实现`priority`属性返回100
  - 实现`isAvailableWithCompletion:`方法，检查AVFoundation框架可用性
  - 实现`supportsFeature:`方法，声明支持的功能（基础合并、音视频混流、硬件加速等）
  - 使用条件编译处理iOS和macOS平台差异（`#if TARGET_OS_IOS` / `#if TARGET_OS_OSX`）
  - _需求：2.1, 3.1, 4.1_

- [ ] **4. 实现视频合并核心逻辑**
  - 实现`mergeWithRequest:completion:`方法
  - 使用`AVMutableComposition`创建可变组合对象
  - 遍历输入文件，使用`AVAsset`加载每个视频片段
  - 将视频轨道和音频轨道添加到composition中
  - 处理时间范围计算（CMTime、CMTimeRange）
  - 实现进度回调机制（基于当前处理的片段索引）
  - 使用`AVAssetExportSession`导出最终文件
  - 配置导出参数（presetName、outputFileType、shouldOptimizeForNetworkUse）
  - 实现取消操作支持（监听cancellationToken）
  - _需求：2.1, 2.5, 3.1, 3.5_

- [ ] **5. 实现分批处理策略**
  - 检测输入文件数量，如果超过阈值（100个）则启用分批处理
  - 根据平台动态调整批次大小（iOS: 100-200，macOS: 200-500）
  - 实现批次合并逻辑：
    - 将输入文件分组
    - 每批生成临时合并文件
    - 递归合并所有临时文件
  - 实现临时文件管理：
    - 在临时目录创建唯一文件名
    - 合并完成后自动清理临时文件
  - 实现跨批次的进度计算和报告
  - _需求：2.2, 3.2, 3.6_

- [ ] **6. 实现错误处理和资源清理**
  - 定义错误码枚举（文件不存在、格式不支持、磁盘空间不足、内存不足等）
  - 实现错误信息本地化（NSLocalizedDescriptionKey）
  - 处理AVFoundation特定错误（AVError）
  - 实现资源清理逻辑：
    - 清理临时文件
    - 取消导出会话
    - 释放AVAsset资源
  - 实现重试机制（可配置重试次数和延迟）
  - 记录详细的错误日志（包含输入文件、配置、错误上下文）
  - _需求：2.4, 3.4, 7.3, 7.4_

### 第三阶段：高级功能和优化

- [ ] **7. 实现分辨率不一致处理**
  - 检测所有输入视频的分辨率
  - 如果检测到不一致，根据scalingStrategy配置：
    - 自动缩放到第一个视频的分辨率
    - 使用`AVVideoComposition`创建视频组合
    - 配置renderSize和instructions
    - 实现智能缩放算法（保持宽高比、居中裁剪等）
  - 记录警告日志
  - _需求：2.3, 3.3_

- [ ] **8. 实现性能监控和统计**
  - 记录合并开始和结束时间
  - 计算总耗时（totalDuration）
  - 统计输入文件数量和总大小
  - 获取输出文件大小
  - 计算平均速度（MB/s）
  - 监控内存占用（使用`task_info`获取峰值内存）
  - 记录批次数量
  - 检测是否使用硬件加速
  - 填充`M3U8MergeStatistics`对象
  - _需求：8.1, 8.2, 8.3_

### 第四阶段：降级策略和处理器选择

- [ ] **9. 实现自动降级和处理器选择逻辑**
  - 在Registry中实现处理器选择算法：
    - 如果指定了preferredProcessor，优先使用
    - 如果指定了processorPriority列表，按顺序尝试
    - 否则按priority降序自动选择
  - 实现可用性检查：
    - 调用`isAvailableWithCompletion:`验证处理器可用性
    - 如果不可用，自动尝试下一个处理器
  - 实现降级日志记录
  - 实现降级通知机制（通过回调或通知中心）
  - 处理所有处理器都不可用的情况（返回清晰错误）
  - _需求：7.1, 7.2, 7.5_

### 第五阶段：模块化和集成

- [ ] **10. 配置CocoaPods和Swift Package Manager集成**
  - 更新`M3U8DownloaderKit.podspec`：
    - 创建`VideoMerge` subspec
    - 配置source_files和public_header_files
    - 添加AVFoundation和CoreMedia框架依赖
    - 设置iOS 15.0+和macOS 12.0+部署目标
  - 更新`Package.swift`：
    - 创建`M3U8VideoMerge` target
    - 配置依赖关系
    - 设置平台版本要求
  - 实现条件编译支持：
    - 使用`#if __has_include(<M3U8VideoMerge/M3U8VideoMerge.h>)`检测模块是否集成
    - 在主模块中提供优雅的降级处理
  - 创建示例Podfile和Package.swift配置
  - _需求：5.1, 5.2, 5.3, 5.4, 5.5_

### 第六阶段：测试和文档

- [ ] **11. 编写单元测试和集成测试**
  - 为核心接口编写单元测试：
    - 测试`M3U8MergeRequest`、`M3U8MergeOptions`、`M3U8MergeResult`的初始化和属性
    - 测试`M3U8VideoProcessorRegistry`的注册和查询功能
  - 为AVFoundation处理器编写集成测试：
    - 测试基础合并功能（少量TS片段）
    - 测试分批处理（大量片段）
    - 测试分辨率不一致处理
    - 测试错误处理（文件不存在、格式不支持等）
    - 测试取消操作
    - 测试进度回调
  - 为降级策略编写测试：
    - 测试处理器选择逻辑
    - 测试自动降级
  - 使用XCTest框架
  - 配置CI/CD自动运行测试
  - 目标测试覆盖率：80%以上
  - _需求：9.1, 9.2_

- [ ] **12. 编写文档和示例代码**
  - 编写架构设计文档：
    - 说明各层级的职责（C#层、C互操作层、Objective-C层）
    - 说明模块划分和依赖关系
    - 说明平台差异处理策略
  - 编写API参考文档：
    - 为所有公共接口添加HeaderDoc注释
    - 生成API文档（使用jazzy或appledoc）
  - 编写集成指南：
    - CocoaPods集成步骤
    - Swift Package Manager集成步骤
    - 模块选择建议（决策树）
  - 编写使用示例：
    - 基础合并示例（Objective-C和Swift）
    - 自定义处理器示例
    - 进度监控示例
    - 错误处理示例
    - 性能优化示例
  - 编写故障排查指南：
    - 常见问题和解决方案
    - 错误码参考
    - 性能优化建议
  - 更新README.md，添加视频合并功能介绍
  - _需求：9.1, 9.2, 9.3_

---

## 实施顺序说明

1. **第一阶段（任务1-2）**：建立核心架构，定义所有接口和数据模型，这是后续所有工作的基础
2. **第二阶段（任务3-6）**：实现AVFoundation视频处理器，这是最核心的功能
3. **第三阶段（任务7-8）**：添加高级功能，提升用户体验和可观测性
4. **第四阶段（任务9）**：实现降级策略，提高系统的健壮性
5. **第五阶段（任务10）**：配置模块化集成，让用户可以灵活选择
6. **第六阶段（任务11-12）**：完善测试和文档，确保质量和可维护性

每个阶段的任务可以并行开发（如果有多个开发者），但建议按顺序完成以降低风险。

---

## 关键里程碑

- ✅ **里程碑1**：完成核心接口定义（任务1-2）
- ✅ **里程碑2**：实现基础视频合并功能（任务3-4）
- ✅ **里程碑3**：实现分批处理和错误处理（任务5-6）
- ✅ **里程碑4**：完成所有高级功能（任务7-9）
- ✅ **里程碑5**：完成模块化集成（任务10）
- ✅ **里程碑6**：完成测试和文档（任务11-12）

---

## 预估工作量

| 任务 | 预估时间 | 优先级 |
|------|---------|--------|
| 任务1：核心接口定义 | 1-2天 | P0 |
| 任务2：处理器注册表 | 1天 | P0 |
| 任务3：AVFoundation处理器核心 | 2-3天 | P0 |
| 任务4：视频合并核心逻辑 | 3-4天 | P0 |
| 任务5：分批处理策略 | 2-3天 | P1 |
| 任务6：错误处理和资源清理 | 2天 | P0 |
| 任务7：分辨率处理 | 1-2天 | P1 |
| 任务8：性能监控 | 1天 | P2 |
| 任务9：降级策略 | 1-2天 | P1 |
| 任务10：模块化集成 | 1天 | P1 |
| 任务11：测试 | 3-4天 | P0 |
| 任务12：文档 | 2-3天 | P1 |

**总计**：约20-30个工作日（单人开发）

---

## 技术风险和缓解措施

### 风险1：AVFoundation性能不达标
- **缓解**：在任务4完成后立即进行性能测试，如果不达标，考虑优化或引入FFmpeg

### 风险2：分批处理逻辑复杂
- **缓解**：在任务5中先实现简单版本，然后逐步优化

### 风险3：平台差异处理困难
- **缓解**：在任务3中使用条件编译清晰分离平台特定代码，提供统一的测试用例

### 风险4：测试覆盖率不足
- **缓解**：在任务11中使用代码覆盖率工具（Xcode Coverage），确保达到80%以上

---

## 依赖关系图

```
任务1（核心接口）
  ↓
任务2（注册表） ← 任务3（AVFoundation处理器）
  ↓                    ↓
任务9（降级策略）    任务4（合并逻辑）
                       ↓
                    任务5（分批处理）
                       ↓
                    任务6（错误处理）
                       ↓
                    任务7（分辨率处理）
                       ↓
                    任务8（性能监控）
                       ↓
                    任务10（模块化）
                       ↓
                 任务11（测试）+ 任务12（文档）
```

---

## 验收标准

完成所有任务后，系统应满足以下标准：

1. ✅ 所有公共接口都有清晰的文档和示例
2. ✅ 单元测试覆盖率达到80%以上
3. ✅ 集成测试覆盖所有主要场景
4. ✅ 性能达到需求文档中的指标（100个1分钟视频30秒内完成）
5. ✅ 内存占用不超过200MB
6. ✅ 应用体积增加不超过5MB（不含FFmpeg）
7. ✅ 支持CocoaPods和Swift Package Manager集成
8. ✅ iOS和macOS共享核心代码
9. ✅ 提供完整的错误处理和降级机制
10. ✅ 提供清晰的集成指南和故障排查文档
