# iOS Library 构建问题 - 快速总结

## 🔴 问题

构建 Core 项目为 iOS Library 时失败，错误：

```
error CS0234: The type or namespace name 'CommandLine' does not exist
error CS0234: The type or namespace name 'Entity' does not exist
```

## 🔍 原因

**Core 项目依赖主项目**，形成循环依赖：

```
N_m3u8DL-RE (主项目 - CLI 应用)
  └─> N_m3u8DL-RE.Core

N_m3u8DL-RE.Core
  └─> N_m3u8DL-RE (主项目) ✗ 循环依赖！
```

具体问题文件：
- `Config/DownloaderConfig.cs` - 引用 `MyOption` 类
- 多个文件引用 `N_m3u8DL_RE.Entity` 命名空间

## ✅ 解决方案

### 方案对比

| 方案 | 难度 | 时间 | 功能 | 推荐度 |
|------|------|------|------|--------|
| 1. 重构依赖 | ⭐⭐⭐⭐⭐ | 长期 | 完整 | ⭐⭐⭐⭐⭐ 长期 |
| 2. 独立项目 | ⭐⭐⭐ | 中期 | 完整 | ⭐⭐⭐⭐ 推荐 |
| 3. 条件编译 | ⭐⭐ | 短期 | 完整 | ⭐⭐ 临时 |
| 4. 仅 Parser | ⭐ | 立即 | 解析 | ⭐⭐⭐ 快速 |

### 🌟 推荐：方案 2 - 创建独立的 iOS Library 项目

创建新项目 `N_m3u8DL-RE.iOS`，包含必要的功能但不依赖主项目。

**优点**：
- ✅ 不影响现有项目
- ✅ 可以精确控制导出的 API
- ✅ 易于维护
- ✅ 功能完整

**实施步骤**：

1. 创建新项目结构
2. 复制必要的代码
3. 移除对主项目的依赖
4. 创建简化的配置类
5. 导出公共 API

### ⚡ 临时方案：构建 Parser 库

在完整方案实施前，可以先构建 Parser 库（仅解析功能）：

```bash
# 使用临时脚本
./build-ios-parser-local.sh

# 或手动构建
./.dotnet/dotnet publish src/N_m3u8DL-RE.Parser/N_m3u8DL-RE.Parser.csproj \
    -c Release \
    -f net9.0-ios \
    -r ios-arm64 \
    -p:PublishAot=true \
    -p:NativeLib=Shared \
    -o output/ios-parser
```

**Parser 库功能**：
- ✅ HLS 解析
- ✅ DASH 解析
- ✅ MSS 解析
- ❌ 下载功能（需要完整方案）

## 📋 下一步行动

### 立即可行（今天）

1. **构建 Parser 库**
   ```bash
   chmod +x build-ios-parser-local.sh
   ./build-ios-parser-local.sh
   ```

2. **验证输出**
   ```bash
   ls -lh output/ios-parser/
   file output/ios-parser/*.dylib
   ```

### 短期计划（本周）

1. **设计 iOS Library API**
   - 确定需要导出的功能
   - 设计简化的配置接口
   - 规划公共 API

2. **创建项目结构**
   ```
   src/N_m3u8DL-RE.iOS/
   ├── Config/
   │   └── iOSDownloaderConfig.cs
   ├── PublicAPI/
   │   └── iOSNativeAPI.cs
   ├── Downloader/
   │   └── (复制必要的下载器代码)
   └── N_m3u8DL-RE.iOS.csproj
   ```

3. **实现核心功能**
   - 下载管理
   - 进度回调
   - 错误处理

### 中期计划（下周）

1. **完整测试**
   - 单元测试
   - 集成测试
   - iOS 设备测试

2. **文档更新**
   - API 文档
   - 集成指南
   - 示例代码

3. **发布**
   - 构建 XCFramework
   - 版本管理
   - 发布说明

## 🔧 临时脚本

已创建以下脚本：

### build-ios-parser-local.sh

构建 Parser 库（仅解析功能）：

```bash
./build-ios-parser-local.sh
```

输出：`output/ios-parser/`

## 📚 相关文档

- **[详细问题分析](iOS-Library-Build-Issue.md)** - 完整的问题说明和所有解决方案
- [本地 .NET 安装](Local-Dotnet-Installation.md)
- [iOS Library 集成](iOS-Library-Integration.md)
- [项目重构文档](../REFACTORING.md)

## 💡 建议

### 如果你需要立即可用的库
→ 使用 **Parser 库**（仅解析功能）

```bash
./build-ios-parser-local.sh
```

### 如果你需要完整的下载功能
→ 实施 **方案 2：创建独立项目**

这需要一些时间，但是最佳的长期解决方案。

### 如果你有时间进行重构
→ 实施 **方案 1：重构依赖关系**

这是最彻底的解决方案，但需要大量工作。

## ❓ 常见问题

### Q: 为什么不能直接构建 Core 项目？

A: Core 项目依赖主项目的类型（如 `MyOption`），形成循环依赖。

### Q: Parser 库有什么功能？

A: Parser 库可以解析 HLS、DASH、MSS 等流媒体格式，但不包含下载功能。

### Q: 什么时候能有完整的下载功能？

A: 需要实施方案 2（创建独立项目）或方案 1（重构依赖），预计需要几天到一周时间。

### Q: 临时方案够用吗？

A: 如果只需要解析功能，Parser 库就够用。如果需要下载功能，需要实施完整方案。

---

**更新时间**：2025-11-16
**状态**：临时方案可用，完整方案待实施
**优先级**：高
