# Homebrew .NET SDK 与 iOS Workload 兼容性问题

## 问题描述

当使用 Homebrew 安装的 .NET SDK 时，尝试安装 iOS workload 会遇到以下错误：

```bash
$ dotnet workload install microsoft-net-sdk-ios
Workload installation failed: Workload ID microsoft-net-sdk-ios is not recognized.
```

## 根本原因

**Homebrew 安装的 .NET SDK 不包含 iOS/Android/MAUI 等移动平台的 workload manifest 文件**。

这是因为：
1. Homebrew 的 .NET 包是精简版本，主要用于服务器端和跨平台开发
2. iOS workload 需要与 Xcode 深度集成，Homebrew 版本不包含这些集成
3. 移动开发 workload 的 manifest 文件在 Homebrew 版本中被移除

验证方法：
```bash
# Homebrew 版本缺少 manifest 目录
ls /opt/homebrew/Cellar/dotnet/9.0.8/libexec/sdk/9.0.109/manifests/
# 输出为空或只有少量 manifest

# 官方版本包含完整 manifest
ls /usr/local/share/dotnet/sdk/9.0.109/manifests/
# 应该包含 microsoft.net.sdk.ios, microsoft.net.sdk.android 等
```

## 解决方案

### 方案 1：安装官方 .NET SDK（推荐用于 iOS 开发）

#### 步骤 1：下载并安装官方 .NET SDK

```bash
# 1. 从官方网站下载 .NET 9.0 SDK
# https://dotnet.microsoft.com/download/dotnet/9.0

# 2. 下载 macOS Installer (.pkg)
# 选择 "macOS x64 Installer" 或 "macOS Arm64 Installer"（根据你的 Mac 芯片）

# 3. 运行下载的 .pkg 文件进行安装
```

#### 步骤 2：配置环境变量优先使用官方版本

编辑 `~/.zshrc` 或 `~/.bash_profile`：

```bash
# 将官方 .NET 路径放在 Homebrew 之前
export PATH="/usr/local/share/dotnet:$PATH"

# 或者完全移除 Homebrew 版本
# brew uninstall dotnet
```

应用更改：
```bash
source ~/.zshrc
```

#### 步骤 3：验证安装

```bash
# 检查 dotnet 路径
which dotnet
# 应该输出: /usr/local/share/dotnet/dotnet

# 检查版本
dotnet --version

# 检查可用的 workload
dotnet workload search ios
```

#### 步骤 4：安装 iOS workload

```bash
# 安装 iOS SDK workload
dotnet workload install ios

# 或者安装完整的 MAUI workload（包含 iOS）
dotnet workload install maui

# 验证安装
dotnet workload list
```

#### 步骤 5：运行构建脚本

```bash
./build-ios-library.sh
```

---

### 方案 2：使用 Homebrew .NET + 非 NativeAOT 构建（不推荐）

如果你想继续使用 Homebrew 版本的 .NET，可以放弃 NativeAOT 编译，改用传统的托管代码方式。

**限制**：
- ❌ 无法生成纯 C 接口的动态库
- ❌ 无法直接在 Objective-C/Swift 中调用
- ❌ 需要在 iOS 应用中嵌入完整的 .NET 运行时
- ✅ 可以构建 iOS 应用程序（但不是 Library）

#### 修改构建方式

创建一个简化的构建脚本 `build-ios-app-homebrew.sh`：

```bash
#!/bin/bash
set -e

echo "=== 使用 Homebrew .NET 构建 iOS 应用 ==="

# 注意：这只能构建应用，不能构建 Library
dotnet publish src/N_m3u8DL-RE/N_m3u8DL-RE.csproj \
    -c Release \
    -f net9.0 \
    -r ios-arm64 \
    -p:PublishAot=false \
    -p:PublishSingleFile=false \
    --self-contained true \
    -o output/ios-app

echo "构建完成（应用程序模式，非 Library）"
```

**这个方案不适合我们的需求**，因为我们需要构建可供外部使用的 Library。

---

### 方案 3：使用 Docker（高级方案）

如果你不想改变本地 .NET 安装，可以使用 Docker：

```bash
# 使用官方 .NET SDK 镜像
docker run --rm -v $(pwd):/app -w /app mcr.microsoft.com/dotnet/sdk:9.0 bash -c "
    dotnet workload install ios && \
    ./build-ios-library.sh
"
```

**限制**：
- 需要安装 Docker
- 构建速度可能较慢
- 需要处理文件权限问题

---

## 推荐方案对比

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **方案 1：官方 SDK** | ✅ 完整功能<br>✅ 官方支持<br>✅ 可构建 Library | ⚠️ 需要重新安装 | **推荐用于 iOS 开发** |
| 方案 2：Homebrew + 非 AOT | ✅ 无需重装 | ❌ 无法构建 Library<br>❌ 功能受限 | 不适合当前需求 |
| 方案 3：Docker | ✅ 隔离环境 | ❌ 复杂度高<br>❌ 速度慢 | CI/CD 环境 |

---

## 最终建议

**强烈建议使用方案 1（安装官方 .NET SDK）**，原因：

1. ✅ 这是 Microsoft 官方推荐的 iOS 开发方式
2. ✅ 可以使用 NativeAOT 生成高性能的原生库
3. ✅ 完整支持所有 iOS workload 功能
4. ✅ 与 Xcode 集成良好
5. ✅ 可以与 Homebrew 版本共存（通过 PATH 控制）

---

## 安装后验证清单

安装官方 SDK 后，运行以下命令验证：

```bash
# 1. 检查 dotnet 路径
which dotnet
# 期望输出: /usr/local/share/dotnet/dotnet

# 2. 检查版本
dotnet --version
# 期望输出: 9.0.xxx

# 3. 列出已安装的 workload
dotnet workload list

# 4. 搜索 iOS workload
dotnet workload search ios

# 5. 检查 Xcode
xcode-select -p
# 期望输出: /Applications/Xcode.app/Contents/Developer

# 6. 测试构建
./build-ios-library.sh
```

---

## 常见问题

### Q1: 安装官方 SDK 后，Homebrew 版本还在怎么办？

A: 通过修改 PATH 环境变量控制优先级：

```bash
# 在 ~/.zshrc 中添加
export PATH="/usr/local/share/dotnet:$PATH"
```

或者完全卸载 Homebrew 版本：
```bash
brew uninstall dotnet
```

### Q2: 可以同时保留两个版本吗？

A: 可以，通过别名或完整路径调用：

```bash
# 官方版本
/usr/local/share/dotnet/dotnet --version

# Homebrew 版本
/opt/homebrew/bin/dotnet --version

# 设置别名
alias dotnet-official='/usr/local/share/dotnet/dotnet'
alias dotnet-brew='/opt/homebrew/bin/dotnet'
```

### Q3: 安装官方 SDK 需要多少空间？

A: 约 1-2 GB（包括 SDK 和 iOS workload）

### Q4: 我的项目依赖 Homebrew 的其他包怎么办？

A: 只替换 .NET SDK，其他 Homebrew 包不受影响。

---

## 参考资料

- [.NET 官方下载页面](https://dotnet.microsoft.com/download)
- [.NET iOS 开发文档](https://learn.microsoft.com/en-us/dotnet/ios/)
- [.NET Workload 管理](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-workload-install)
- [NativeAOT 部署指南](https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/)
