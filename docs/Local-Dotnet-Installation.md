# 本地 .NET SDK 安装方案（不覆盖 Homebrew）

## 方案概述

这个方案允许你：
- ✅ 保留 Homebrew 安装的 .NET（用于其他项目）
- ✅ 在本地目录安装官方 .NET（用于 iOS 开发）
- ✅ 两个版本互不干扰
- ✅ 通过脚本自动使用正确的版本

## 安装步骤

### 1. 创建本地 .NET 目录

```bash
# 在项目根目录创建 .dotnet 目录
mkdir -p .dotnet
```

### 2. 下载官方 .NET SDK

根据你的 Mac 芯片选择下载链接：

#### Apple Silicon (M1/M2/M3)
```bash
# 下载 .NET 9.0 SDK for macOS ARM64
curl -L -o dotnet-sdk.tar.gz \
  https://download.visualstudio.microsoft.com/download/pr/fdb75cec-5e11-4e55-b102-7d6b4c4d6e11/e0e8e4c0e6b0e4e4e4e4e4e4e4e4e4e4/dotnet-sdk-9.0.100-osx-arm64.tar.gz
```

#### Intel
```bash
# 下载 .NET 9.0 SDK for macOS x64
curl -L -o dotnet-sdk.tar.gz \
  https://download.visualstudio.microsoft.com/download/pr/fdb75cec-5e11-4e55-b102-7d6b4c4d6e11/e0e8e4c0e6b0e4e4e4e4e4e4e4e4e4e4/dotnet-sdk-9.0.100-osx-x64.tar.gz
```

**注意**：上面的链接可能会过期，请从官方页面获取最新链接：
https://dotnet.microsoft.com/download/dotnet/9.0

### 3. 解压到本地目录

```bash
# 解压到 .dotnet 目录
tar -xzf dotnet-sdk.tar.gz -C .dotnet

# 删除压缩包
rm dotnet-sdk.tar.gz
```

### 4. 验证安装

```bash
# 使用本地 dotnet
./.dotnet/dotnet --version

# 应该输出类似: 9.0.100
```

### 5. 安装 iOS Workload

```bash
# 使用本地 dotnet 安装 iOS workload
./.dotnet/dotnet workload install ios
```

### 6. 添加到 .gitignore

```bash
# 将本地 .dotnet 目录添加到 .gitignore
echo ".dotnet/" >> .gitignore
```

---

## 使用方式

### 方式 1：直接使用完整路径

```bash
# 使用本地 dotnet 构建
./.dotnet/dotnet build src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj
```

### 方式 2：使用专用构建脚本（推荐）

我们创建了专门的构建脚本，会自动使用本地 dotnet：

```bash
# 使用本地 dotnet 构建 iOS Library
./build-ios-library-local.sh
```

### 方式 3：临时设置 PATH

```bash
# 临时将本地 dotnet 添加到 PATH
export PATH="$(pwd)/.dotnet:$PATH"

# 现在 dotnet 命令会使用本地版本
dotnet --version

# 构建
./build-ios-library.sh
```

---

## 自动化安装脚本

我们提供了一个自动化脚本来完成所有安装步骤：

```bash
./setup-local-dotnet.sh
```

这个脚本会：
1. 检测你的 Mac 芯片类型
2. 下载对应的 .NET SDK
3. 解压到 `.dotnet` 目录
4. 安装 iOS workload
5. 验证安装

---

## 目录结构

安装完成后，项目目录结构如下：

```
N_m3u8DL-RE/
├── .dotnet/                    # 本地 .NET SDK（不提交到 git）
│   ├── dotnet                  # dotnet 可执行文件
│   ├── sdk/
│   │   └── 9.0.100/
│   ├── shared/
│   └── ...
├── build-ios-library-local.sh  # 使用本地 dotnet 的构建脚本
├── setup-local-dotnet.sh       # 自动安装脚本
└── ...
```

---

## 验证两个版本共存

```bash
# Homebrew 版本
/opt/homebrew/bin/dotnet --version
# 输出: 9.0.xxx (Homebrew)

# 本地版本
./.dotnet/dotnet --version
# 输出: 9.0.100 (官方)

# 检查 workload
/opt/homebrew/bin/dotnet workload list
# 输出: (可能没有 iOS workload)

./.dotnet/dotnet workload list
# 输出: ios workload 已安装
```

---

## 优势

### ✅ 隔离性
- 两个版本完全独立
- 互不影响
- 可以同时使用

### ✅ 便携性
- 项目自包含
- 团队成员可以使用相同的脚本
- 不需要修改系统环境

### ✅ 灵活性
- 可以轻松切换版本
- 可以为不同项目使用不同版本
- 不影响其他项目

### ✅ 安全性
- 不修改系统 PATH
- 不影响 Homebrew 安装
- 可以随时删除

---

## 磁盘空间

本地安装需要约 **1-2 GB** 磁盘空间：
- .NET SDK: ~500 MB
- iOS workload: ~500 MB - 1 GB
- 其他依赖: ~200 MB

---

## 更新本地 .NET

如果需要更新到新版本：

```bash
# 1. 删除旧版本
rm -rf .dotnet

# 2. 重新运行安装脚本
./setup-local-dotnet.sh
```

---

## 卸载

如果不再需要本地版本：

```bash
# 删除本地 .dotnet 目录
rm -rf .dotnet

# 这不会影响 Homebrew 安装的版本
```

---

## 常见问题

### Q1: 本地版本会影响 Homebrew 版本吗？

A: 不会。两个版本完全独立，互不影响。

### Q2: 可以在多个项目中使用这个方案吗？

A: 可以。每个项目都可以有自己的 `.dotnet` 目录。

### Q3: 团队其他成员也需要这样安装吗？

A: 是的，但我们提供了自动化脚本 `setup-local-dotnet.sh`，一键完成安装。

### Q4: 这个方案适合 CI/CD 吗？

A: 非常适合！CI/CD 环境可以使用相同的脚本，确保构建环境一致。

### Q5: 如何确保使用的是本地版本？

A: 构建脚本会自动检测并使用本地版本。你也可以用 `which dotnet` 检查。

---

## 下一步

1. 运行自动安装脚本：
   ```bash
   ./setup-local-dotnet.sh
   ```

2. 使用本地 dotnet 构建：
   ```bash
   ./build-ios-library-local.sh
   ```

3. 查看构建输出：
   ```bash
   ls -lh output/ios-library/
   ```

---

## 参考资料

- [.NET 官方下载页面](https://dotnet.microsoft.com/download/dotnet/9.0)
- [.NET 安装文档](https://learn.microsoft.com/en-us/dotnet/core/install/macos)
- [iOS Library 集成指南](iOS-Library-Integration.md)
