# N_m3u8DL-RE 项目架构说明

## 📁 项目结构

本项目采用模块化架构设计，将核心业务逻辑与用户界面分离，便于维护和扩展。

### 项目组成

```
N_m3u8DL-RE/
├── src/
│   ├── N_m3u8DL-RE/              # 命令行前端程序（可执行程序）
│   ├── N_m3u8DL-RE.Core/         # 核心业务逻辑库
│   ├── N_m3u8DL-RE.Common/       # 通用工具和实体库
│   ├── N_m3u8DL-RE.Parser/       # 流媒体解析器库
│   └── N_m3u8DL-RE.Tests/        # 单元测试项目
```

## 🏗️ 架构设计

### 1. N_m3u8DL-RE（命令行前端）
**类型**: 可执行程序 (Exe)  
**职责**: 
- 命令行参数解析和验证
- 用户交互和输出展示
- 调用核心库功能
- UI相关的列（Column）组件

**主要组件**:
- `Program.cs` - 程序入口点
- `CommandLine/` - 命令行参数处理
- `Column/` - 控制台输出列组件

### 2. N_m3u8DL-RE.Core（核心业务库）
**类型**: 类库 (Library)  
**职责**: 
- 下载管理和调度
- 文件处理和合并
- 加密解密
- 核心业务逻辑

**主要模块**:
- `DownloadManager/` - 下载管理器
  - `SimpleDownloadManager.cs` - 普通下载管理
  - `SimpleLiveRecordManager2.cs` - 直播录制管理
  - `HTTPLiveRecordManager.cs` - HTTP直播录制
- `Downloader/` - 下载器实现
  - `IDownloader.cs` - 下载器接口
  - `SimpleDownloader.cs` - 简单下载器
- `Processor/` - 内容处理器
  - `DemoProcessor.cs` - 示例处理器
  - `NowehoryzontyUrlProcessor.cs` - URL处理器
- `Crypto/` - 加密解密
  - `AESUtil.cs` - AES加密工具
  - `ChaCha20Util.cs` - ChaCha20加密工具
- `Util/` - 工具类
  - `DownloadUtil.cs` - 下载工具
  - `FilterUtil.cs` - 过滤工具
  - `MergeUtil.cs` - 合并工具
  - `MP4DecryptUtil.cs` - MP4解密工具
  - 等等...
- `Entity/` - 核心实体类
- `Enum/` - 枚举定义
- `Config/` - 配置类

### 3. N_m3u8DL-RE.Common（通用库）
**类型**: 类库 (Library)  
**职责**: 
- 通用实体定义
- 日志系统
- 通用工具函数
- 资源和本地化

**主要模块**:
- `Entity/` - 通用实体（StreamSpec、MediaSegment等）
- `Enum/` - 通用枚举
- `Log/` - 日志系统
- `Resource/` - 资源和本地化
- `Util/` - 通用工具类

### 4. N_m3u8DL-RE.Parser（解析器库）
**类型**: 类库 (Library)  
**职责**: 
- HLS流解析
- DASH流解析
- MSS流解析
- MP4文件处理

**主要模块**:
- `Extractor/` - 流提取器
  - `HLSExtractor.cs` - HLS提取器
  - `DASHExtractor2.cs` - DASH提取器
  - `MSSExtractor.cs` - MSS提取器
- `Processor/` - 内容处理器
- `Mp4/` - MP4文件处理
- `Constants/` - 常量定义

### 5. N_m3u8DL-RE.Tests（测试项目）
**类型**: 测试项目  
**职责**: 单元测试和集成测试

## 🔗 依赖关系

```
N_m3u8DL-RE (Exe)
    ├─→ N_m3u8DL-RE.Core
    │       ├─→ N_m3u8DL-RE.Common
    │       └─→ N_m3u8DL-RE.Parser
    │               └─→ N_m3u8DL-RE.Common
    └─→ N_m3u8DL-RE.Parser

N_m3u8DL-RE.Tests
    ├─→ N_m3u8DL-RE.Core
    ├─→ N_m3u8DL-RE.Common
    └─→ N_m3u8DL-RE.Parser
```

## 🎯 架构优势

### 1. **模块化分离**
- 核心功能与用户界面完全分离
- 每个模块职责清晰，易于理解和维护

### 2. **可扩展性**
- 可以轻松添加新的前端（GUI、Web服务等）
- 只需引用 `N_m3u8DL-RE.Core` 库即可复用所有核心功能

### 3. **测试友好**
- 核心库可以独立进行单元测试
- 不依赖命令行界面，测试更加纯粹

### 4. **代码复用**
- 其他项目可以直接引用核心功能库
- 避免代码重复

### 5. **多平台支持**
- 所有项目都支持 `net9.0` 和 `net9.0-ios`
- 便于跨平台部署

## 🚀 使用示例

### 作为命令行工具使用
```bash
# 构建命令行程序
dotnet build src/N_m3u8DL-RE/N_m3u8DL-RE.csproj -c Release

# 运行
./N_m3u8DL-RE [options]
```

### 作为库引用使用
```csharp
// 在你的项目中引用 N_m3u8DL-RE.Core
using N_m3u8DL_RE.Core.DownloadManager;
using N_m3u8DL_RE.Core.Config;

// 使用核心功能
var downloadManager = new SimpleDownloadManager(...);
await downloadManager.StartDownloadAsync();
```

## 📝 开发指南

### 添加新功能
1. **核心功能**: 添加到 `N_m3u8DL-RE.Core`
2. **解析相关**: 添加到 `N_m3u8DL-RE.Parser`
3. **通用工具**: 添加到 `N_m3u8DL-RE.Common`
4. **UI相关**: 添加到 `N_m3u8DL-RE`

### 命名空间规范
- 主程序: `N_m3u8DL_RE.*`
- 核心库: `N_m3u8DL_RE.Core.*`
- 通用库: `N_m3u8DL_RE.Common.*`
- 解析器: `N_m3u8DL_RE.Parser.*`

## 🔧 构建说明

### 构建所有项目
```bash
dotnet build src/N_m3u8DL-RE.sln -c Release
```

### 构建iOS版本
```bash
./build-ios.sh
```

### 运行测试
```bash
dotnet test src/N_m3u8DL-RE.Tests/N_m3u8DL-RE.Tests.csproj
```

## 📦 发布

### 发布命令行程序
```bash
dotnet publish src/N_m3u8DL-RE/N_m3u8DL-RE.csproj \
    -c Release \
    -r <runtime-identifier> \
    --self-contained true
```

### 发布为NuGet包（Core库）
```bash
dotnet pack src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj \
    -c Release \
    -o ./packages
```

## 🔄 迁移说明

本架构是从原有的单体结构重构而来，主要变更：

1. **创建了 Core 库**: 将核心业务逻辑从主程序中提取出来
2. **更新了命名空间**: 
   - 原 `N_m3u8DL_RE.DownloadManager` → `N_m3u8DL_RE.Core.DownloadManager`
   - 原 `N_m3u8DL_RE.Util` → `N_m3u8DL_RE.Core.Util`
   - 等等...
3. **调整了依赖关系**: 主程序现在依赖 Core 库

## 📄 许可证

遵循项目原有许可证。
