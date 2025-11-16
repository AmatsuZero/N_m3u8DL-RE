# iOS Library 构建 - 完整方案对比

## 📊 方案对比

| 特性 | 方案 1：本地安装 | 方案 2：全局安装 | Homebrew（不可行） |
|------|-----------------|-----------------|-------------------|
| **不影响现有环境** | ✅ 是 | ⚠️ 需修改 PATH | ✅ 是 |
| **iOS workload 支持** | ✅ 完整支持 | ✅ 完整支持 | ❌ 不支持 |
| **安装难度** | ⭐ 一键安装 | ⭐⭐ 需手动配置 | ⭐ 简单但不可用 |
| **项目隔离** | ✅ 完全隔离 | ❌ 全局共享 | ✅ 隔离 |
| **团队协作** | ✅ 统一脚本 | ⚠️ 需统一配置 | ❌ 不可用 |
| **CI/CD 友好** | ✅ 非常友好 | ⚠️ 需配置环境 | ❌ 不可用 |
| **磁盘空间** | ~1-2 GB | ~1-2 GB | ~500 MB |
| **推荐度** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ❌ 不推荐 |

---

## 🌟 方案 1：本地安装（强烈推荐）

### 概述

将 .NET SDK 安装到项目的 `.dotnet` 目录，不影响系统的其他 .NET 安装。

### 优势

1. **完全隔离**
   - Homebrew .NET 保持不变
   - 项目有自己的 .NET 版本
   - 互不干扰

2. **简单易用**
   - 一键安装脚本
   - 自动配置
   - 无需修改系统环境

3. **团队协作**
   - 所有成员使用相同版本
   - 统一的构建脚本
   - 减少环境差异

4. **CI/CD 友好**
   - 容易集成到 CI/CD 流程
   - 可重复的构建环境
   - 无需额外配置

### 快速开始

```bash
# 1. 安装本地 .NET SDK（3-5 分钟）
./setup-local-dotnet.sh

# 2. 构建 iOS Library（1-2 分钟）
./build-ios-library-local.sh

# 3. 查看输出
ls -lh output/ios-library/
```

### 详细文档

- [快速开始指南](LOCAL-DOTNET-QUICKSTART.md) ⭐ 从这里开始
- [详细安装说明](docs/Local-Dotnet-Installation.md)

### 适用场景

- ✅ 想保留 Homebrew .NET
- ✅ 多个项目需要不同 .NET 版本
- ✅ 团队协作开发
- ✅ CI/CD 自动化构建
- ✅ 不想修改系统环境

---

## 📦 方案 2：全局安装官方 SDK

### 概述

从官方网站下载 .pkg 安装包，安装到系统目录 `/usr/local/share/dotnet/`。

### 优势

1. **官方标准**
   - Microsoft 推荐的安装方式
   - 完整的功能支持
   - 定期更新

2. **系统集成**
   - 与 Xcode 深度集成
   - 全局可用
   - 标准路径

### 安装步骤

#### 步骤 1：下载安装包

访问：https://dotnet.microsoft.com/download/dotnet/9.0

下载对应的 `.pkg` 文件：
- Apple Silicon: macOS Arm64 Installer
- Intel: macOS x64 Installer

#### 步骤 2：安装

双击 `.pkg` 文件，按向导完成安装。

#### 步骤 3：配置 PATH

编辑 `~/.zshrc`：

```bash
# 优先使用官方 .NET SDK
export PATH="/usr/local/share/dotnet:$PATH"
```

应用配置：

```bash
source ~/.zshrc
```

#### 步骤 4：安装 workload

```bash
dotnet workload install ios
```

#### 步骤 5：构建

```bash
./build-ios-library-simple.sh
```

### 详细文档

- [官方 SDK 安装指南](docs/Install-Official-Dotnet-SDK.md)
- [Homebrew 问题说明](docs/iOS-Homebrew-Dotnet-Issue.md)

### 适用场景

- ✅ 只做 iOS/macOS 开发
- ✅ 不需要保留 Homebrew 版本
- ✅ 希望使用官方标准安装
- ✅ 单人开发

### 注意事项

- ⚠️ 会修改系统 PATH
- ⚠️ 可能与 Homebrew 版本冲突（需要配置优先级）
- ⚠️ 团队成员需要统一配置

---

## ❌ 方案 3：Homebrew .NET（不可行）

### 为什么不可行？

Homebrew 安装的 .NET SDK **不包含 iOS workload 的 manifest 文件**。

### 验证

```bash
# 检查 manifest 目录
ls /opt/homebrew/Cellar/dotnet/9.0.8/libexec/sdk/9.0.109/manifests/
# 输出: 空或只有少量 manifest（没有 iOS）

# 尝试安装 iOS workload
dotnet workload install ios
# 错误: Workload ID ios is not recognized
```

### 技术原因

1. Homebrew 的 .NET 包是精简版本
2. 主要用于服务器端和跨平台开发
3. 移动平台 workload 被移除
4. 与 Xcode 集成不完整

### 详细说明

查看：[docs/iOS-Homebrew-Dotnet-Issue.md](docs/iOS-Homebrew-Dotnet-Issue.md)

---

## 🎯 推荐决策树

```
开始
  │
  ├─ 想保留 Homebrew .NET？
  │   ├─ 是 → 使用方案 1（本地安装）⭐⭐⭐⭐⭐
  │   └─ 否 → 继续
  │
  ├─ 团队协作开发？
  │   ├─ 是 → 使用方案 1（本地安装）⭐⭐⭐⭐⭐
  │   └─ 否 → 继续
  │
  ├─ 需要 CI/CD？
  │   ├─ 是 → 使用方案 1（本地安装）⭐⭐⭐⭐⭐
  │   └─ 否 → 继续
  │
  └─ 单人开发，不介意修改系统？
      └─ 是 → 使用方案 2（全局安装）⭐⭐⭐
```

**结论**：大多数情况下，**方案 1（本地安装）是最佳选择**。

---

## 📚 文档索引

### 快速开始

- **[LOCAL-DOTNET-QUICKSTART.md](LOCAL-DOTNET-QUICKSTART.md)** ⭐ 推荐从这里开始
- [CURRENT-ISSUE-SUMMARY.md](CURRENT-ISSUE-SUMMARY.md) - 问题总结

### 方案 1：本地安装

- [docs/Local-Dotnet-Installation.md](docs/Local-Dotnet-Installation.md) - 详细说明
- `setup-local-dotnet.sh` - 自动安装脚本
- `build-ios-library-local.sh` - 构建脚本

### 方案 2：全局安装

- [docs/Install-Official-Dotnet-SDK.md](docs/Install-Official-Dotnet-SDK.md) - 安装指南
- [docs/iOS-Homebrew-Dotnet-Issue.md](docs/iOS-Homebrew-Dotnet-Issue.md) - 问题说明

### 其他文档

- [docs/iOS-Library-Integration.md](docs/iOS-Library-Integration.md) - 集成指南
- [docs/iOS-Build-Troubleshooting.md](docs/iOS-Build-Troubleshooting.md) - 故障排查
- [iOS-Library-README.md](iOS-Library-README.md) - 项目说明

---

## 🚀 立即开始

### 推荐路径（方案 1）

```bash
# 1. 查看快速开始指南
cat LOCAL-DOTNET-QUICKSTART.md

# 2. 安装本地 .NET SDK
./setup-local-dotnet.sh

# 3. 构建 iOS Library
./build-ios-library-local.sh

# 4. 验证输出
ls -lh output/ios-library/
```

### 备选路径（方案 2）

```bash
# 1. 查看安装指南
cat docs/Install-Official-Dotnet-SDK.md

# 2. 手动下载并安装 .pkg 文件
open https://dotnet.microsoft.com/download/dotnet/9.0

# 3. 配置环境变量
echo 'export PATH="/usr/local/share/dotnet:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 4. 安装 workload
dotnet workload install ios

# 5. 构建
./build-ios-library-simple.sh
```

---

## ❓ 常见问题

### Q1: 两个方案可以同时使用吗？

A: 可以，但没必要。选择一个即可。

### Q2: 方案 1 会影响方案 2 吗？

A: 不会。方案 1 是项目级别，方案 2 是系统级别，互不影响。

### Q3: 如何在两个方案之间切换？

A: 
- 方案 1：使用 `./build-ios-library-local.sh`
- 方案 2：使用 `./build-ios-library-simple.sh`

### Q4: 哪个方案更快？

A: 构建速度相同。安装速度方案 1 更快（自动化）。

### Q5: 团队应该用哪个方案？

A: **强烈推荐方案 1**，因为：
- 统一的构建环境
- 减少环境差异
- 易于 CI/CD 集成

---

## 📞 需要帮助？

如果遇到问题，请查看：

1. [LOCAL-DOTNET-QUICKSTART.md](LOCAL-DOTNET-QUICKSTART.md) - 快速开始
2. [docs/iOS-Build-Troubleshooting.md](docs/iOS-Build-Troubleshooting.md) - 故障排查
3. [CURRENT-ISSUE-SUMMARY.md](CURRENT-ISSUE-SUMMARY.md) - 问题总结

---

**准备好了吗？开始构建你的 iOS Library！** 🎉

```bash
./setup-local-dotnet.sh
```
