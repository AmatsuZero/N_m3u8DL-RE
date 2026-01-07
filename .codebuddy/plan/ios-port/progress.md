# iOS移植实施进度记录

## 当前状态

**日期**: 2026-01-07
**当前任务**: 任务2 - 提取并重构下载管理器

## 已完成任务

### ✅ 任务1：创建iOS核心库项目 (已完成)

**完成内容**:
- 创建了 `N_m3u8DL-RE.Core` 项目目录
- 创建了项目文件 `N_m3u8DL-RE.Core.csproj`
  - 配置为类库输出类型
  - 目标框架：net10.0
  - 引用了 Common 和 Parser 项目
  - 不依赖UI框架（无Spectre.Console、System.CommandLine引用）
- 将Core项目添加到解决方案文件中
- 配置了Debug和Release构建配置

**文件变更**:
- 新建: `/src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj`
- 修改: `/src/N_m3u8DL-RE.sln`

## 进行中任务

### 🔄 任务2：提取并重构下载管理器 (进行中)

**已完成部分**:
1. ✅ 创建了日志接口抽象 (`ILogger.cs`, `NullLogger`)
2. ✅ 创建了进度回调接口 (`IDownloadProgressCallback.cs`, `DownloadProgress`, `NullProgressCallback`)
3. ✅ 创建了下载器接口 (`IDownloader.cs`)
4. ✅ 重构了SimpleDownloader类：
   - 移除了Spectre.Console依赖
   - 使用ILogger接口替代Logger静态调用
   - 添加了CancellationToken支持
   - 保留了核心下载和解密逻辑

**待完成部分**:
1. ⏳ 复制Crypto模块（AESUtil, ChaCha20Util, CSChaCha20）
2. ⏳ 复制必要的Util类（DownloadUtil, ImageHeaderUtil, OtherUtil）
3. ⏳ 复制Config和Entity类
4. ⏳ 重构SimpleDownloadManager（更复杂，需要大量UI代码移除）

**分析结果**:

#### SimpleDownloader类分析
- **位置**: `/src/N_m3u8DL-RE/Downloader/SimpleDownloader.cs`
- **大小**: 153行，5.9KB
- **依赖**:
  - ✅ `N_m3u8DL_RE.Common.Entity` - 可移植
  - ✅ `N_m3u8DL_RE.Common.Enum` - 可移植
  - ❌ `N_m3u8DL_RE.Common.Log.Logger` - 需要抽象化
  - ✅ `N_m3u8DL_RE.Config.DownloaderConfig` - 可移植
  - ✅ `N_m3u8DL_RE.Crypto` - 可移植
  - ✅ `N_m3u8DL_RE.Entity.DownloadResult` - 可移植
  - ✅ `N_m3u8DL_RE.Util` - 部分可移植
  - ❌ `Spectre.Console` - 需要移除（仅用于EscapeMarkup）

**重构计划**:
1. 先创建日志接口抽象（ILogger）
2. 复制SimpleDownloader到Core项目
3. 移除Spectre.Console依赖
4. 替换Logger静态调用为ILogger接口
5. 添加进度回调机制
6. 添加CancellationToken支持

#### SimpleDownloadManager类分析
- **位置**: `/src/N_m3u8DL-RE/DownloadManager/SimpleDownloadManager.cs`
- **大小**: 776行，36.8KB
- **复杂度**: 高（包含大量UI代码）
- **主要依赖**:
  - ❌ `Spectre.Console` - 大量使用（进度条、表格、颜色标记）
  - ❌ `N_m3u8DL_RE.Column.*` - UI列定义，需要移除
  - ✅ 核心下载逻辑 - 可移植
  - ❌ ffmpeg调用 - 需要重构为接口
  - ❌ mp4decrypt调用 - 需要重构

**重构策略**:
- 将SimpleDownloadManager拆分为两部分：
  1. **核心下载逻辑** → 移至Core项目
  2. **UI展示逻辑** → 保留在原项目
- 创建进度回调接口替代Spectre.Console进度条
- 将文件合并逻辑抽象为接口（为后续视频处理器做准备）

## 下一步行动

### 立即执行
1. 创建日志接口抽象（ILogger、LogLevel枚举）
2. 创建进度回调接口（IDownloadProgressCallback）
3. 复制并重构SimpleDownloader类

### 待执行
- 任务3：提取流媒体解析器
- 任务4：提取加密解密模块
- 任务5：重构文件处理工具

## 技术决策记录

### 决策1：日志接口设计
**问题**: 如何替代Logger静态类？
**决策**: 创建ILogger接口，通过依赖注入传递
**理由**: 
- 符合SOLID原则
- 便于iOS端注入自定义日志实现
- 支持单元测试

### 决策2：进度回调设计
**问题**: 如何替代Spectre.Console进度条？
**决策**: 创建基于委托的进度回调机制
**理由**:
- 简单直接，易于iOS端集成
- 支持多种UI框架
- 性能开销小

## 注意事项

1. **保持原项目可用**: 重构过程中不要破坏原有的命令行工具功能
2. **渐进式重构**: 先移植简单模块，再处理复杂模块
3. **接口优先**: 先设计接口，再实现具体功能
4. **测试验证**: 每完成一个模块，确保能够编译通过

## 文件结构规划

```
src/N_m3u8DL-RE.Core/
├── Abstraction/
│   ├── ILogger.cs
│   ├── IDownloadProgressCallback.cs
│   └── IVideoProcessor.cs (后续)
├── Downloader/
│   ├── IDownloader.cs
│   └── SimpleDownloader.cs
├── DownloadManager/
│   └── SimpleDownloadManager.cs (重构版)
├── Crypto/
│   ├── AESUtil.cs
│   ├── ChaCha20Util.cs
│   └── CSChaCha20.cs
└── Util/
    └── (待定)
```
