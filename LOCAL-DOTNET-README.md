# 本地 .NET SDK 方案 - 完整指南

## 🎯 这是什么？

这是一个**不影响 Homebrew 安装**的 .NET SDK 本地安装方案，专门用于 iOS Library 开发。

## ⚡ 三步开始

```bash
# 1. 安装（3-5 分钟）
./setup-local-dotnet.sh

# 2. 构建（1-2 分钟）
./build-ios-library-local.sh

# 3. 完成！
ls -lh output/ios-library/
```

## ✨ 为什么选择这个方案？

### ✅ 优势

- **不影响现有环境**：Homebrew .NET 保持不变
- **完全隔离**：项目有自己的 .NET 版本
- **一键安装**：自动化脚本，无需手动配置
- **团队友好**：统一的构建环境
- **CI/CD 就绪**：易于集成到自动化流程

### 📊 与其他方案对比

| 特性 | 本地安装 | 全局安装 | Homebrew |
|------|---------|---------|----------|
| 不影响现有环境 | ✅ | ⚠️ | ✅ |
| iOS 支持 | ✅ | ✅ | ❌ |
| 安装难度 | ⭐ 简单 | ⭐⭐ 中等 | ❌ 不可用 |
| 团队协作 | ✅ | ⚠️ | ❌ |

详细对比：[SOLUTION-COMPARISON.md](SOLUTION-COMPARISON.md)

## 📋 详细步骤

### 步骤 1：安装本地 .NET SDK

```bash
./setup-local-dotnet.sh
```

这个脚本会：
- ✅ 自动检测你的 Mac 芯片类型（Apple Silicon 或 Intel）
- ✅ 下载对应的 .NET 9.0 SDK
- ✅ 解压到项目的 `.dotnet` 目录
- ✅ 安装 iOS workload
- ✅ 更新 `.gitignore`

**预计时间**：3-5 分钟（取决于网络速度）

### 步骤 2：构建 iOS Library

```bash
./build-ios-library-local.sh
```

这个脚本会：
- ✅ 自动使用本地的 .NET SDK
- ✅ 构建 iOS 设备版本（arm64）
- ✅ 输出到 `output/ios-library/` 目录

**预计时间**：1-2 分钟

### 步骤 3：验证输出

```bash
# 查看生成的文件
ls -lh output/ios-library/

# 应该看到：
# - *.dylib（动态库文件）
# - *.h（C 头文件）
```

## 🔍 验证安装

### 检查两个版本共存

```bash
# Homebrew 版本（保持不变）
/opt/homebrew/bin/dotnet --version
# 输出: 9.0.xxx

# 本地版本（新安装）
./.dotnet/dotnet --version
# 输出: 9.0.100

# Homebrew 版本没有 iOS workload
/opt/homebrew/bin/dotnet workload list
# 输出: (可能为空)

# 本地版本有 iOS workload
./.dotnet/dotnet workload list
# 输出: ios workload 已安装 ✓
```

## 📁 目录结构

```
N_m3u8DL-RE/
├── .dotnet/                          # 本地 .NET SDK（不提交到 git）
│   ├── dotnet                        # dotnet 可执行文件
│   ├── sdk/9.0.100/
│   └── ...
├── output/                           # 构建输出（不提交到 git）
│   └── ios-library/
│       ├── *.dylib                   # 动态库
│       └── *.h                       # 头文件
├── setup-local-dotnet.sh             # 安装脚本 ⭐
├── build-ios-library-local.sh        # 构建脚本 ⭐
└── docs/
    ├── Local-Dotnet-Installation.md  # 详细文档
    └── ...
```

## 🐛 故障排查

### 问题 1：下载失败

```bash
# 手动下载
open https://dotnet.microsoft.com/download/dotnet/9.0
# 下载 .tar.gz 格式（不是 .pkg）
# 重命名为 dotnet-sdk.tar.gz
# 放在项目根目录
tar -xzf dotnet-sdk.tar.gz -C .dotnet
./.dotnet/dotnet workload install ios
```

### 问题 2：构建失败

```bash
# 检查安装
ls -la .dotnet/

# 重新安装
rm -rf .dotnet
./setup-local-dotnet.sh
```

### 问题 3：workload 未安装

```bash
# 手动安装
./.dotnet/dotnet workload install ios

# 验证
./.dotnet/dotnet workload list
```

更多问题：[docs/iOS-Build-Troubleshooting.md](docs/iOS-Build-Troubleshooting.md)

## 💾 磁盘空间

需要约 **1-2 GB**：
- .NET SDK: ~500 MB
- iOS workload: ~500 MB - 1 GB
- 构建输出: ~50-100 MB

## 🗑️ 卸载

```bash
# 删除本地 .NET SDK
rm -rf .dotnet

# 删除构建输出
rm -rf output

# 不会影响 Homebrew 安装
```

## 📚 完整文档

### 快速开始
- **[LOCAL-DOTNET-QUICKSTART.md](LOCAL-DOTNET-QUICKSTART.md)** ⭐ 推荐阅读

### 详细文档
- [docs/Local-Dotnet-Installation.md](docs/Local-Dotnet-Installation.md) - 详细安装说明
- [SOLUTION-COMPARISON.md](SOLUTION-COMPARISON.md) - 方案对比
- [CURRENT-ISSUE-SUMMARY.md](CURRENT-ISSUE-SUMMARY.md) - 问题总结

### 其他方案
- [docs/Install-Official-Dotnet-SDK.md](docs/Install-Official-Dotnet-SDK.md) - 全局安装方案
- [docs/iOS-Homebrew-Dotnet-Issue.md](docs/iOS-Homebrew-Dotnet-Issue.md) - Homebrew 问题说明

### 集成和使用
- [docs/iOS-Library-Integration.md](docs/iOS-Library-Integration.md) - 集成到 Xcode
- [docs/iOS-Build-Troubleshooting.md](docs/iOS-Build-Troubleshooting.md) - 故障排查

## ❓ 常见问题

### Q: 会影响我的 Homebrew .NET 吗？

A: **不会**。两个版本完全独立，互不影响。

### Q: 团队其他成员也需要这样做吗？

A: **是的**，但很简单：
```bash
git pull
./setup-local-dotnet.sh
./build-ios-library-local.sh
```

### Q: 可以在 CI/CD 中使用吗？

A: **可以**！非常适合 CI/CD：
```yaml
# GitHub Actions 示例
- name: Setup local .NET
  run: ./setup-local-dotnet.sh

- name: Build iOS Library
  run: ./build-ios-library-local.sh
```

### Q: 如何更新 .NET 版本？

A: 
```bash
rm -rf .dotnet
./setup-local-dotnet.sh
```

### Q: 为什么不用 Homebrew 版本？

A: Homebrew 版本**不支持 iOS workload**。详见：[docs/iOS-Homebrew-Dotnet-Issue.md](docs/iOS-Homebrew-Dotnet-Issue.md)

## 🎉 下一步

安装完成后：

1. **集成到 Xcode**
   ```bash
   cat docs/iOS-Library-Integration.md
   ```

2. **查看 Swift 示例**
   ```bash
   cat examples/ios/SwiftExample.swift
   ```

3. **查看 Objective-C 示例**
   ```bash
   cat examples/ios/ObjectiveCExample.m
   ```

## 🚀 立即开始

```bash
./setup-local-dotnet.sh
```

---

**有问题？** 查看 [LOCAL-DOTNET-QUICKSTART.md](LOCAL-DOTNET-QUICKSTART.md) 或 [SOLUTION-COMPARISON.md](SOLUTION-COMPARISON.md)
