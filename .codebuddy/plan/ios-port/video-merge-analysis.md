# 视频片段合并方案分析与实施计划

## 1. 背景与目标

### 1.1 当前状态
根据原有C#实现的分析，N_m3u8DL-RE目前使用以下两种方式合并视频片段：

1. **二进制直接拼接**（`BinaryMerge`）
   - 适用于：字幕文件、简单的TS流
   - 实现：`MergeUtil.CombineMultipleFilesIntoSingleFile()`
   - 优点：速度快、无需外部依赖
   - 缺点：仅适用于特定格式，无法处理需要重新编码的场景

2. **FFmpeg合并**（默认方式）
   - 适用于：MP4、M4A等容器格式
   - 实现：`MergeUtil.MergeByFFmpeg()`
   - 使用方式：
     - 默认使用 `concat` 协议：`-i concat:"file1.ts|file2.ts|..."`
     - 可选使用 `concat demuxer`：`-f concat -safe 0 -i filelist.txt`
   - 功能：
     - 支持音视频混流（`-map 0:v? -map 0:a? -map 0:s?`）
     - 支持元数据写入（日期、标题、版权等）
     - 支持AAC过滤器（`-bsf:a aac_adtstoasc`）
     - 支持多种输出格式（MP4、MKV、TS、FLV等）
   - 特殊处理：
     - 大于1800个分片时，先分批合并再最终合并
     - 支持添加封面图片
     - 支持多音轨处理

### 1.2 iOS移植目标
在iOS平台上实现视频片段合并功能，需要考虑：
- **体积限制**：避免引入过大的外部库
- **性能要求**：充分利用iOS硬件加速
- **兼容性**：支持常见的HLS/DASH流格式
- **灵活性**：提供多种实现方案供用户选择

---

## 2. 方案一：VideoToolbox/AVFoundation 原生方案

### 2.1 技术栈
- **AVFoundation**：高层API，用于音视频合成
  - `AVMutableComposition`：组合容器
  - `AVMutableCompositionTrack`：音视频轨道
  - `AVAssetExportSession`：导出会话
- **VideoToolbox**：低层API，用于硬件编解码（可选）

### 2.2 可行性分析

#### ✅ 优势
1. **零依赖**：系统原生框架，无需额外库
2. **体积小**：不增加应用体积
3. **硬件加速**：自动使用GPU加速
4. **系统集成**：与iOS生态完美集成
5. **稳定性高**：Apple官方维护

#### ⚠️ 限制与挑战

根据调研结果，AVFoundation存在以下限制：

1. **轨道数量限制**
   - 最多支持8-16个轨道（取决于设备和iOS版本）
   - 对于M3U8下载场景，通常每个分片是独立文件，合并时不会超过此限制

2. **内存占用问题**
   - `AVAssetExportSession` 可能将整个文件加载到内存
   - 对于大量分片（如1800+），需要分批处理
   - 建议策略：每批处理100-200个分片

3. **格式兼容性问题**
   - **`AVAssetExportPresetPassthrough`** 存在已知bug：
     - 可能导致帧冻结
     - 每个片段保持独立轨道，降低兼容性
   - **解决方案**：使用 `AVAssetExportPresetHighestQuality` 或其他质量预设

4. **分辨率不一致问题**
   - 合并不同分辨率的视频可能产生黑边或拉伸
   - 输出分辨率通常匹配第一个视频
   - **解决方案**：检测分辨率不一致时，使用 `AVVideoComposition` 进行缩放

5. **时间精度问题**
   - 需要使用 `CMTime` 精确控制时间（建议 `timescale=600`）
   - 避免片段间出现黑帧或跳帧

6. **后台执行限制**
   - 导出任务必须在前台启动
   - 可以在后台继续执行，但不能在后台启动新任务

### 2.3 适用场景

✅ **适合使用AVFoundation的场景**：
- 标准HLS/DASH流（分辨率一致）
- 分片数量适中（<1000个）
- 需要保持最小应用体积
- 不需要复杂的音视频处理

❌ **不适合使用AVFoundation的场景**：
- 需要复杂的音视频过滤器
- 需要转码或重新编码
- 需要处理非标准格式
- 需要精细的编码参数控制

### 2.4 实施步骤

#### 步骤1：创建 `AVFoundationProcessor` 类
```swift
class AVFoundationProcessor: IVideoProcessor {
    func mergeSegments(
        inputFiles: [URL],
        outputURL: URL,
        options: MergeOptions,
        progressHandler: ((Double) -> Void)?
    ) async throws -> MergeResult
}
```

#### 步骤2：实现基础合并逻辑
```swift
func mergeSegments(inputFiles: [URL], outputURL: URL) async throws {
    let composition = AVMutableComposition()
    var currentTime = CMTime.zero
    
    // 1. 检测所有视频的分辨率
    let resolutions = try await detectResolutions(inputFiles)
    let needsScaling = !resolutions.allSatisfy { $0 == resolutions.first }
    
    // 2. 创建视频和音频轨道
    guard let videoTrack = composition.addMutableTrack(
        withMediaType: .video,
        preferredTrackID: kCMPersistentTrackID_Invalid
    ) else { throw MergeError.trackCreationFailed }
    
    guard let audioTrack = composition.addMutableTrack(
        withMediaType: .audio,
        preferredTrackID: kCMPersistentTrackID_Invalid
    ) else { throw MergeError.trackCreationFailed }
    
    // 3. 逐个插入片段
    for (index, url) in inputFiles.enumerated() {
        let asset = AVURLAsset(url: url)
        
        // 插入视频轨道
        if let sourceVideoTrack = try await asset.loadTracks(withMediaType: .video).first {
            try videoTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: asset.duration),
                of: sourceVideoTrack,
                at: currentTime
            )
        }
        
        // 插入音频轨道
        if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first {
            try audioTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: asset.duration),
                of: sourceAudioTrack,
                at: currentTime
            )
        }
        
        currentTime = CMTimeAdd(currentTime, asset.duration)
    }
    
    // 4. 如果需要缩放，创建 AVVideoComposition
    var videoComposition: AVVideoComposition?
    if needsScaling {
        videoComposition = try createScalingComposition(
            composition: composition,
            targetResolution: resolutions.first!
        )
    }
    
    // 5. 导出
    try await exportComposition(
        composition: composition,
        videoComposition: videoComposition,
        outputURL: outputURL
    )
}
```

#### 步骤3：实现分批处理逻辑
```swift
func mergeLargeSegmentList(
    inputFiles: [URL],
    outputURL: URL,
    batchSize: Int = 100
) async throws {
    // 如果分片数量少于批次大小，直接合并
    if inputFiles.count <= batchSize {
        try await mergeSegments(inputFiles: inputFiles, outputURL: outputURL)
        return
    }
    
    // 分批合并
    var tempFiles: [URL] = []
    let batches = inputFiles.chunked(into: batchSize)
    
    for (index, batch) in batches.enumerated() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("batch_\(index).mp4")
        
        try await mergeSegments(inputFiles: batch, outputURL: tempURL)
        tempFiles.append(tempURL)
    }
    
    // 最终合并
    try await mergeSegments(inputFiles: tempFiles, outputURL: outputURL)
    
    // 清理临时文件
    for tempFile in tempFiles {
        try? FileManager.default.removeItem(at: tempFile)
    }
}
```

#### 步骤4：实现进度报告
```swift
func exportComposition(
    composition: AVMutableComposition,
    videoComposition: AVVideoComposition?,
    outputURL: URL,
    progressHandler: ((Double) -> Void)?
) async throws {
    guard let exportSession = AVAssetExportSession(
        asset: composition,
        presetName: AVAssetExportPresetHighestQuality
    ) else {
        throw MergeError.exportSessionCreationFailed
    }
    
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4
    exportSession.videoComposition = videoComposition
    exportSession.shouldOptimizeForNetworkUse = true
    
    // 监控进度
    let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
        progressHandler?(Double(exportSession.progress))
    }
    
    await exportSession.export()
    progressTimer.invalidate()
    
    guard exportSession.status == .completed else {
        throw MergeError.exportFailed(exportSession.error)
    }
}
```

#### 步骤5：集成到 `IVideoProcessor` 接口
```csharp
// C# 接口定义
public interface IVideoProcessor
{
    string Name { get; }
    int Priority { get; }
    Task<bool> IsAvailableAsync();
    Task<MergeResult> MergeAsync(MergeRequest request, CancellationToken cancellationToken);
}

// Swift 实现通过 C 互操作层暴露
[UnmanagedCallersOnly(EntryPoint = "avfoundation_merge")]
public static int AVFoundationMerge(
    IntPtr inputFilesPtr,
    int fileCount,
    IntPtr outputPathPtr,
    IntPtr optionsPtr,
    IntPtr progressCallbackPtr
)
{
    // 调用 Swift 实现
    // ...
}
```

### 2.5 性能优化建议

1. **使用 `AVAssetExportPresetMediumQuality`**：在保证质量的前提下提升速度
2. **并行处理**：分批合并时可以使用多线程
3. **内存管理**：及时释放 `AVAsset` 对象
4. **缓存策略**：对于重复下载的流，缓存中间结果

### 2.6 预期效果

- **体积增加**：0 MB（系统框架）
- **性能**：中等（受限于AVFoundation的实现）
- **兼容性**：高（支持标准MP4/M4S格式）
- **功能完整性**：中等（基础合并功能）

---

## 3. 方案二：FFmpeg 集成方案

### 3.1 技术栈选择

#### 选项A：ffmpeg-kit
- **项目地址**：https://github.com/arthenica/ffmpeg-kit
- **状态**：⚠️ 已宣布退役，二进制文件将逐步移除
  - <6.0 版本：2025年2月移除
  - 6.0 版本：2025年4月移除
- **建议**：不推荐用于新项目

#### 选项B：自行编译 FFmpeg
- **优势**：完全控制、可定制
- **挑战**：编译复杂、维护成本高
- **体积**：可通过裁剪优化

#### 选项C：使用 FFmpeg.AutoGen（.NET绑定）
- **优势**：与.NET生态集成
- **挑战**：需要处理iOS上的P/Invoke
- **可行性**：需要进一步验证

### 3.2 体积分析

根据调研，FFmpeg库的体积取决于包含的功能：

| 包类型 | 体积 | 包含功能 |
|--------|------|----------|
| min | 8-12 MB | 基础H.264解码 |
| audio | 15-22 MB | 音频格式转换 |
| video | 25-35 MB | 视频过滤器、转码 |
| full | 50-80 MB | 完整功能 |
| full-gpl | 70-100 MB | GPL增强功能 |

**优化策略**：
1. 仅支持 arm64 架构（排除模拟器架构）
2. 裁剪不需要的编解码器
3. 使用静态链接并启用编译器优化
4. 仅包含必要的功能模块

**预期体积**：15-25 MB（针对M3U8下载场景优化）

### 3.3 功能对比

| 功能 | AVFoundation | FFmpeg |
|------|--------------|--------|
| 基础合并 | ✅ | ✅ |
| 音视频混流 | ✅ | ✅ |
| 格式转换 | ⚠️ 有限 | ✅ 完整 |
| 视频过滤器 | ❌ | ✅ |
| 字幕处理 | ⚠️ 有限 | ✅ |
| 元数据写入 | ✅ | ✅ |
| 硬件加速 | ✅ 自动 | ⚠️ 需配置 |
| 分辨率缩放 | ✅ | ✅ |
| AAC过滤器 | ❌ | ✅ |
| 自定义编码参数 | ❌ | ✅ |

### 3.4 实施步骤

#### 步骤1：评估FFmpeg集成方式

**任务26：评估ffmpeg集成方案**
- [ ] 研究自行编译FFmpeg的可行性
  - 下载FFmpeg源码
  - 研究iOS编译脚本（参考 gas-preprocessor.pl）
  - 配置最小化编译选项（仅H.264、AAC、MP4容器）
  - 编译 arm64 和 arm64-simulator 版本
  - 测试基本功能（合并、混流）
  
- [ ] 评估FFmpeg.AutoGen在iOS上的可用性
  - 测试P/Invoke在NativeAOT下的兼容性
  - 验证函数指针和回调机制
  - 测试内存管理和资源释放
  
- [ ] 分析主流iOS项目的FFmpeg集成方式
  - 研究VLC for iOS的实现
  - 研究ijkplayer的实现
  - 总结最佳实践
  
- [ ] 测试基本功能
  - 合并多个MP4/TS文件
  - 音视频混流
  - 元数据写入
  - 性能测试（与AVFoundation对比）
  
- [ ] 记录优势和劣势
  - 功能完整性
  - 性能表现
  - 体积影响
  - 维护成本

#### 步骤2：实现 `FFmpegProcessor` 类

**任务27：实现FFmpeg视频处理器**

```csharp
public class FFmpegProcessor : IVideoProcessor
{
    public string Name => "FFmpeg";
    public int Priority => 50; // 中等优先级
    
    private readonly string _ffmpegPath;
    
    public async Task<bool> IsAvailableAsync()
    {
        // 检查FFmpeg库是否可用
        return File.Exists(_ffmpegPath);
    }
    
    public async Task<MergeResult> MergeAsync(
        MergeRequest request,
        CancellationToken cancellationToken)
    {
        // 1. 准备输入文件列表
        var inputList = PrepareInputList(request.InputFiles);
        
        // 2. 构建FFmpeg命令
        var command = BuildMergeCommand(
            inputList,
            request.OutputPath,
            request.Options
        );
        
        // 3. 执行FFmpeg
        var result = await ExecuteFFmpegAsync(
            command,
            request.ProgressCallback,
            cancellationToken
        );
        
        return result;
    }
    
    private string BuildMergeCommand(
        string inputList,
        string outputPath,
        MergeOptions options)
    {
        var sb = new StringBuilder();
        sb.Append("-loglevel warning -nostdin ");
        
        // 使用 concat demuxer
        sb.Append($"-f concat -safe 0 -i \"{inputList}\" ");
        
        // 映射所有流
        sb.Append("-map 0:v? -map 0:a? -map 0:s? ");
        
        // 编码选项
        sb.Append("-c copy ");
        
        // AAC过滤器（如果需要）
        if (options.UseAACFilter)
        {
            sb.Append("-bsf:a aac_adtstoasc ");
        }
        
        // 元数据
        if (options.WriteMetadata)
        {
            sb.Append($"-metadata date=\"{DateTime.Now:o}\" ");
            sb.Append($"-metadata title=\"{options.Title}\" ");
        }
        
        // 输出文件
        sb.Append($"-y \"{outputPath}\"");
        
        return sb.ToString();
    }
    
    private async Task<MergeResult> ExecuteFFmpegAsync(
        string command,
        Action<double> progressCallback,
        CancellationToken cancellationToken)
    {
        // 使用 Process 或 FFmpeg.AutoGen 执行
        // 解析进度输出
        // 处理取消请求
        // ...
    }
}
```

#### 步骤3：编译和打包

**任务28：编译包含ffmpeg的XCFramework**

1. **编译FFmpeg库**
   ```bash
   # 配置编译选项
   ./configure \
     --enable-cross-compile \
     --arch=arm64 \
     --target-os=darwin \
     --enable-pic \
     --disable-programs \
     --disable-doc \
     --enable-protocol=file \
     --enable-demuxer=mov,mpegts,hls \
     --enable-muxer=mp4,mpegts \
     --enable-decoder=h264,aac \
     --enable-encoder=h264,aac \
     --enable-parser=h264,aac \
     --enable-bsf=aac_adtstoasc,h264_mp4toannexb
   
   make -j8
   ```

2. **创建XCFramework**
   ```bash
   xcodebuild -create-xcframework \
     -library libN_m3u8DL_RE_Core_arm64.a \
     -headers include/ \
     -library libN_m3u8DL_RE_Core_arm64_sim.a \
     -headers include/ \
     -output M3u8DownloaderKit-FFmpeg.xcframework
   ```

3. **体积优化**
   - 使用 `strip` 移除符号表
   - 使用 `lipo` 合并架构
   - 压缩XCFramework

#### 步骤4：更新文档

**任务29：更新文档说明ffmpeg集成**

创建 `docs/ffmpeg-integration.md`，包含：
- FFmpeg版本选择指南
- 功能对比表
- 体积对比
- 性能对比
- 使用示例
- 故障排查

---

## 4. 方案对比与推荐

### 4.1 综合对比

| 维度 | AVFoundation | FFmpeg |
|------|--------------|--------|
| **体积** | 0 MB | 15-25 MB |
| **性能** | 高（硬件加速） | 中（软件实现） |
| **功能** | 基础 | 完整 |
| **兼容性** | 标准格式 | 所有格式 |
| **维护成本** | 低 | 中 |
| **开发难度** | 中 | 高 |
| **稳定性** | 高 | 高 |

### 4.2 推荐策略

**阶段性实施策略**：

#### 第一阶段：实现AVFoundation方案（必须）
- **优先级**：高
- **目标**：提供基础功能，保持最小体积
- **适用场景**：80%的常规HLS/DASH下载
- **时间估计**：1-2周

#### 第二阶段：评估FFmpeg方案（可选）
- **优先级**：中
- **目标**：提供完整功能，满足高级需求
- **适用场景**：需要高级功能的用户
- **时间估计**：2-3周

#### 第三阶段：提供双版本（可选）
- **基础版**：仅包含AVFoundation，体积最小
- **完整版**：包含FFmpeg，功能完整
- **用户选择**：根据需求下载对应版本

### 4.3 实施建议

1. **先实现AVFoundation方案**
   - 满足大部分用户需求
   - 验证架构设计的合理性
   - 快速发布可用版本

2. **并行评估FFmpeg方案**
   - 研究编译和集成方式
   - 测试功能和性能
   - 评估维护成本

3. **根据评估结果决定是否集成FFmpeg**
   - 如果AVFoundation能满足90%的需求，可以暂缓FFmpeg集成
   - 如果用户强烈需要高级功能，则实施FFmpeg集成
   - 考虑提供插件机制，让用户自行选择

---

## 5. 风险与缓解措施

### 5.1 AVFoundation方案风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 轨道数量限制 | 低 | M3U8场景不会超限 |
| 内存占用过高 | 中 | 实施分批处理 |
| 格式兼容性问题 | 中 | 使用质量预设而非Passthrough |
| 分辨率不一致 | 低 | 实施分辨率检测和缩放 |

### 5.2 FFmpeg方案风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 体积过大 | 高 | 裁剪不需要的功能 |
| 编译复杂 | 中 | 使用成熟的编译脚本 |
| 维护成本高 | 中 | 定期更新FFmpeg版本 |
| App Store审核 | 低 | 使用LGPL版本 |

---

## 6. 下一步行动

### 立即执行（本周）
1. ✅ 完成原有实现分析（已完成）
2. ⏳ 实现 `AVFoundationProcessor` 基础版本
3. ⏳ 编写单元测试验证基础功能

### 短期计划（2周内）
1. 完善 `AVFoundationProcessor` 功能
   - 分批处理逻辑
   - 分辨率检测和缩放
   - 进度报告
   - 错误处理
2. 集成到 `IVideoProcessor` 接口
3. 在示例应用中测试

### 中期计划（1个月内）
1. 评估FFmpeg集成方案
   - 编译测试
   - 功能测试
   - 性能测试
2. 根据评估结果决定是否实施
3. 更新文档和示例

---

## 7. 结论

**推荐方案**：
1. **优先实现AVFoundation方案**，满足基础需求，保持最小体积
2. **并行评估FFmpeg方案**，为高级功能做准备
3. **提供灵活的架构**，允许用户根据需求选择处理器

**预期效果**：
- 基础版本：0 MB额外体积，满足80%的使用场景
- 完整版本：15-25 MB额外体积，满足100%的使用场景
- 用户可根据需求选择合适的版本

**关键成功因素**：
1. 接口设计足够灵活，支持多种实现
2. 分批处理逻辑健壮，避免内存问题
3. 错误处理完善，提供清晰的错误信息
4. 文档完整，帮助用户做出正确选择
