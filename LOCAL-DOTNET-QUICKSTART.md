# 本地 .NET SDK 方案 - 快速开始

## 🎯 方案优势

这个方案允许你：
- ✅ **保留 Homebrew 版本**：不影响现有的 .NET 安装
- ✅ **项目隔离**：每个项目可以有自己的 .NET 版本
- ✅ **团队协作**：团队成员使用相同的脚本和版本
- ✅ **简单易用**：一键安装，自动配置

## 🚀 三步开始

### 步骤 1：安装本地 .NET SDK

```bash
./setup-local-dotnet.sh
```

这个脚本会：
- 自动检测你的 Mac 芯片类型（Apple Silicon 或 Intel）
- 下载对应的 .NET 9.0 SDK
- 解压到项目的 `.dotnet` 目录
- 安装 iOS workload
- 更新 `.gitignore`

**预计时间**：3-5 分钟（取决于网络速度）

### 步骤 2：构建 iOS Library

```bash
./build-ios-library-local.sh
```

这个脚本会：
- 自动使用本地的 .NET SDK
- 构建 iOS 设备版本（arm64）
- 输出到 `output/ios-library/` 目录

**预计时间**：1-2 分钟

### 步骤 3：查看输出

```bash
ls -lh output/ios-library/
```

你应该看到：
- `*.dylib` - 动态库文件
- `*.h` - C 头文件

## 📋 完整示例

```bash
# 克隆项目（如果还没有）
cd /Users/samzhjiang/Github/N_m3u8DL-RE

# 1. 安装本地 .NET SDK
./setup-local-dotnet.sh

# 2. 构建 iOS Library
./build-ios-library-local.sh

# 3. 查看输出
ls -lh output/ios-library/

# 4. 验证本地 dotnet
./.dotnet/dotnet --version
./.dotnet/dotnet workload list
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
# 输出: (可能为空或没有 ios)

# 本地版本有 iOS workload
./.dotnet/dotnet workload list
# 输出: ios workload 已安装
```

### 检查构建输出

```bash
# 查看生成的库文件
file output/ios-library/*.dylib

# 应该输出类似：
# output/ios-library/N_m3u8DL_RE_Core.dylib: Mach-O 64-bit dynamically linked shared library arm64
```

## 📁 目录结构

安装完成后：

```
N_m3u8DL-RE/
├── .dotnet/                          # 本地 .NET SDK（不提交到 git）
│   ├── dotnet                        # dotnet 可执行文件
│   ├── sdk/
│   │   └── 9.0.100/
│   ├── shared/
│   └── ...
├── output/                           # 构建输出（不提交到 git）
│   └── ios-library/
│       ├── *.dylib                   # 动态库
│       └── *.h                       # 头文件
├── setup-local-dotnet.sh             # 安装脚本
├── build-ios-library-local.sh        # 构建脚本
└── docs/
    └── Local-Dotnet-Installation.md  # 详细文档
```

## ⚙️ 高级用法

### 临时使用本地 dotnet

```bash
# 临时添加到 PATH
export PATH="$(pwd)/.dotnet:$PATH"

# 现在 dotnet 命令会使用本地版本
dotnet --version

# 可以直接使用 dotnet 命令
dotnet build
dotnet publish
```

### 在其他脚本中使用

```bash
#!/bin/bash

# 使用本地 dotnet
DOTNET="$(pwd)/.dotnet/dotnet"

# 构建项目
$DOTNET build MyProject.csproj

# 运行测试
$DOTNET test
```

### 更新本地 .NET

```bash
# 删除旧版本
rm -rf .dotnet

# 重新安装
./setup-local-dotnet.sh
```

## 🐛 故障排查

### 问题 1：下载失败

**症状**：
```
❌ 下载失败
```

**解决方案**：
1. 检查网络连接
2. 手动下载：
   - 访问：https://dotnet.microsoft.com/download/dotnet/9.0
   - 下载 "macOS ARM64 Installer" 或 "macOS x64 Installer"
   - 选择 `.tar.gz` 格式（不是 `.pkg`）
   - 将文件重命名为 `dotnet-sdk.tar.gz`
   - 放在项目根目录
   - 运行：`tar -xzf dotnet-sdk.tar.gz -C .dotnet`
   - 运行：`./.dotnet/dotnet workload install ios`

### 问题 2：构建失败

**症状**：
```
❌ 错误: 未找到本地 .NET SDK
```

**解决方案**：
```bash
# 检查 .dotnet 目录是否存在
ls -la .dotnet/

# 如果不存在，运行安装脚本
./setup-local-dotnet.sh
```

### 问题 3：workload 未安装

**症状**：
```
❌ 错误: 未安装 iOS workload
```

**解决方案**：
```bash
# 手动安装 workload
./.dotnet/dotnet workload install ios

# 验证
./.dotnet/dotnet workload list
```

## 💾 磁盘空间

本地安装需要约 **1-2 GB** 磁盘空间：
- .NET SDK: ~500 MB
- iOS workload: ~500 MB - 1 GB
- 构建输出: ~50-100 MB

## 🗑️ 卸载

如果不再需要本地版本：

```bash
# 删除本地 .NET SDK
rm -rf .dotnet

# 删除构建输出
rm -rf output

# 这不会影响 Homebrew 安装的版本
```

## 📚 相关文档

- [详细安装说明](docs/Local-Dotnet-Installation.md)
- [iOS Library 集成指南](docs/iOS-Library-Integration.md)
- [Homebrew .NET 问题说明](docs/iOS-Homebrew-Dotnet-Issue.md)
- [构建故障排查](docs/iOS-Build-Troubleshooting.md)

## 🎉 下一步

安装完成后，你可以：

1. ✅ 构建 iOS Library
2. ✅ 集成到 Xcode 项目
3. ✅ 在 Swift/Objective-C 中调用

开始集成：
```bash
# 查看集成指南
cat docs/iOS-Library-Integration.md

# 或在浏览器中打开
open docs/iOS-Library-Integration.md
```

## ❓ 常见问题

### Q: 这会影响我的 Homebrew .NET 吗？

A: **不会**。两个版本完全独立，互不影响。

### Q: 团队其他成员也需要这样做吗？

A: **是的**，但很简单：
```bash
git pull
./setup-local-dotnet.sh
./build-ios-library-local.sh
```

### Q: 可以在 CI/CD 中使用吗？

A: **可以**！这个方案非常适合 CI/CD：
```yaml
# GitHub Actions 示例
- name: Setup local .NET
  run: ./setup-local-dotnet.sh

- name: Build iOS Library
  run: ./build-ios-library-local.sh
```

### Q: 如何切换回 Homebrew 版本？

A: 只需使用完整路径：
```bash
# 使用 Homebrew 版本
/opt/homebrew/bin/dotnet --version

# 使用本地版本
./.dotnet/dotnet --version
```

---

**准备好了吗？开始吧！**

```bash
./setup-local-dotnet.sh
```
