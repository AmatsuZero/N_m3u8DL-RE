# iOS Library 构建问题分析

## 🔴 当前问题

在构建 iOS Library 时遇到编译错误：

```
error CS0234: The type or namespace name 'CommandLine' does not exist in the namespace 'N_m3u8DL_RE'
error CS0234: The type or namespace name 'Entity' does not exist in the namespace 'N_m3u8DL_RE'
error CS0234: The type or namespace name 'Config' does not exist in the namespace 'N_m3u8DL_RE'
```

## 🔍 问题根源

### 项目结构

当前项目结构：

```
src/
├── N_m3u8DL-RE/              # 主项目（CLI 应用）
│   ├── CommandLine/          # 命令行参数解析
│   ├── Entity/               # 主项目实体类
│   └── ...
├── N_m3u8DL-RE.Core/         # 核心下载逻辑
│   ├── Config/
│   ├── Downloader/
│   ├── Entity/               # Core 实体类
│   └── ...
├── N_m3u8DL-RE.Common/       # 公共类库
│   └── Entity/               # 公共实体类
└── N_m3u8DL-RE.Parser/       # 解析器
```

### 依赖关系

**正常依赖**（正确）：
```
N_m3u8DL-RE (主项目)
  ├─> N_m3u8DL-RE.Core
  ├─> N_m3u8DL-RE.Common
  └─> N_m3u8DL-RE.Parser
```

**问题依赖**（错误）：
```
N_m3u8DL-RE.Core
  ├─> N_m3u8DL-RE.Common ✓
  ├─> N_m3u8DL-RE.Parser ✓
  └─> N_m3u8DL-RE (主项目) ✗ 循环依赖！
```

### 具体问题

Core 项目中的以下文件引用了主项目的类型：

1. **Config/DownloaderConfig.cs**
   - 引用：`using N_m3u8DL_RE.CommandLine;`
   - 使用：`MyOption` 类

2. **多个文件引用 `N_m3u8DL_RE.Entity`**
   - Downloader/IDownloader.cs
   - Downloader/SimpleDownloader.cs
   - DownloadManager/*.cs
   - Util/*.cs

这些引用导致 Core 项目依赖主项目，形成循环依赖。

## ✅ 解决方案

### 方案 1：重构依赖关系（推荐，但工作量大）

将被 Core 依赖的类型移到 Common 或 Core 项目中：

1. **移动 MyOption 到 Core.Config**
   ```
   N_m3u8DL-RE/CommandLine/MyOption.cs
   → N_m3u8DL-RE.Core/Config/MyOption.cs
   ```

2. **移动 Entity 类到 Core.Entity**
   ```
   N_m3u8DL-RE/Entity/*.cs
   → N_m3u8DL-RE.Core/Entity/*.cs
   ```

3. **更新所有引用**
   - 将 `using N_m3u8DL_RE.CommandLine;` 改为 `using N_m3u8DL_RE.Core.Config;`
   - 将 `using N_m3u8DL_RE.Entity;` 改为 `using N_m3u8DL_RE.Core.Entity;`

**优点**：
- ✅ 彻底解决依赖问题
- ✅ 项目结构更清晰
- ✅ Core 可以独立构建

**缺点**：
- ⚠️ 需要大量重构
- ⚠️ 可能影响现有功能
- ⚠️ 需要全面测试

### 方案 2：创建独立的 iOS Library 项目（推荐，快速）

创建一个新的项目 `N_m3u8DL-RE.iOS`，只包含 iOS Library 需要的功能：

```
src/
└── N_m3u8DL-RE.iOS/          # 新项目
    ├── PublicAPI/            # 公共 API
    ├── Config/               # 简化的配置
    └── N_m3u8DL-RE.iOS.csproj
```

**优点**：
- ✅ 不影响现有项目
- ✅ 快速实现
- ✅ 可以精确控制导出的 API

**缺点**：
- ⚠️ 需要维护额外的项目
- ⚠️ 可能有代码重复

### 方案 3：条件编译（临时方案）

使用条件编译排除有问题的代码：

```csharp
#if !IOS
using N_m3u8DL_RE.CommandLine;
#endif

namespace N_m3u8DL_RE.Core.Config;

internal class DownloaderConfig
{
#if !IOS
    public required MyOption MyOptions { get; set; }
#else
    // iOS 简化版本
    public Dictionary<string, string> Options { get; set; } = new();
#endif
    // ...
}
```

**优点**：
- ✅ 快速实现
- ✅ 不需要大量重构

**缺点**：
- ⚠️ 代码可读性差
- ⚠️ 维护困难
- ⚠️ 不是长期解决方案

### 方案 4：仅导出 Parser 功能（最简单）

如果 iOS Library 只需要解析功能，可以只构建 Parser 项目：

```bash
dotnet publish src/N_m3u8DL-RE.Parser/N_m3u8DL-RE.Parser.csproj \
    -c Release \
    -f net9.0-ios \
    -r ios-arm64 \
    -p:PublishAot=true \
    -p:NativeLib=Shared
```

**优点**：
- ✅ 最简单
- ✅ Parser 项目没有循环依赖
- ✅ 立即可用

**缺点**：
- ⚠️ 功能有限（只有解析，没有下载）

## 🎯 推荐方案

根据你的需求选择：

### 如果需要完整的下载功能
→ **方案 2：创建独立的 iOS Library 项目**

这是最平衡的方案：
- 不影响现有项目
- 可以快速实现
- 功能完整
- 易于维护

### 如果只需要解析功能
→ **方案 4：仅导出 Parser**

最简单快速的方案。

### 如果有时间进行重构
→ **方案 1：重构依赖关系**

长期来看最好的方案，但需要投入时间。

## 📝 下一步行动

### 立即可行的方案（方案 4）

1. 修改构建脚本，构建 Parser 项目：

```bash
# 修改 build-ios-library-local.sh
PARSER_PROJECT="src/N_m3u8DL-RE.Parser/N_m3u8DL-RE.Parser.csproj"

"$DOTNET_BIN" publish "$PARSER_PROJECT" \
    -c Release \
    -f net9.0-ios \
    -r ios-arm64 \
    -p:PublishAot=true \
    -p:NativeLib=Shared \
    -o output/ios-library
```

2. 验证构建：

```bash
./build-ios-library-local.sh
```

### 中期方案（方案 2）

1. 创建新项目 `N_m3u8DL-RE.iOS`
2. 复制必要的代码
3. 移除对主项目的依赖
4. 创建简化的 API
5. 更新构建脚本

## 🔧 临时解决方案

在等待完整解决方案时，可以先构建 Parser 项目：

```bash
# 创建临时构建脚本
cat > build-ios-parser.sh << 'EOF'
#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
DOTNET_BIN="$PROJECT_ROOT/.dotnet/dotnet"
PARSER_PROJECT="src/N_m3u8DL-RE.Parser/N_m3u8DL-RE.Parser.csproj"

echo "=== 构建 iOS Parser Library ==="

"$DOTNET_BIN" publish "$PARSER_PROJECT" \
    -c Release \
    -f net9.0-ios \
    -r ios-arm64 \
    -p:PublishAot=true \
    -p:NativeLib=Shared \
    -o output/ios-parser

echo "✓ 构建完成: output/ios-parser"
EOF

chmod +x build-ios-parser.sh
./build-ios-parser.sh
```

## 📚 相关文档

- [项目重构文档](../REFACTORING.md)
- [iOS Library 集成指南](iOS-Library-Integration.md)
- [本地 .NET 安装指南](Local-Dotnet-Installation.md)

---

**更新时间**：2025-11-16
**状态**：待解决
**优先级**：高
