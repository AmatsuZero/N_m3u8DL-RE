# iOS Library 构建问题总结

## 🔴 当前问题

在尝试构建 iOS Library 时遇到错误：

```bash
Workload installation failed: Workload ID microsoft-net-sdk-ios is not recognized.
```

## 🔍 问题根源

你当前使用的是 **Homebrew 安装的 .NET SDK**（路径：`/opt/homebrew/bin/dotnet`）。

**Homebrew 版本的 .NET SDK 不包含 iOS/Android/MAUI 等移动平台的 workload manifest 文件**，因此无法安装 iOS workload，也就无法构建 iOS Library。

验证方法：
```bash
# 检查 dotnet 路径
which dotnet
# 如果输出包含 "homebrew" 或 "/opt/homebrew/"，则是 Homebrew 版本

# 检查 manifest 目录
ls /opt/homebrew/Cellar/dotnet/9.0.8/libexec/sdk/9.0.109/manifests/
# Homebrew 版本此目录为空或只有少量 manifest
```

## ✅ 解决方案

我们提供了两种解决方案，**推荐使用方案 1（本地安装）**：

---

### 🌟 方案 1：本地安装 .NET SDK（推荐）⭐

**优势**：
- ✅ 不影响 Homebrew 安装的 .NET
- ✅ 项目隔离，互不干扰
- ✅ 一键安装，自动配置
- ✅ 适合团队协作和 CI/CD

#### 快速开始（三步完成）

```bash
# 1. 安装本地 .NET SDK
./setup-local-dotnet.sh

# 2. 构建 iOS Library
./build-ios-library-local.sh

# 3. 查看输出
ls -lh output/ios-library/
```

**就这么简单！** 🎉

详细说明请查看：[LOCAL-DOTNET-QUICKSTART.md](LOCAL-DOTNET-QUICKSTART.md)

---

### 方案 2：全局安装官方 .NET SDK

#### 步骤 1：下载官方 SDK

访问：https://dotnet.microsoft.com/download/dotnet/9.0

根据你的 Mac 芯片下载：
- **Apple Silicon (M1/M2/M3)**: macOS Arm64 Installer
- **Intel**: macOS x64 Installer

#### 步骤 2：安装 .pkg 文件

双击下载的 `.pkg` 文件完成安装。

#### 步骤 3：配置环境变量

编辑 `~/.zshrc`：

```bash
nano ~/.zshrc
```

在文件末尾添加：

```bash
# 优先使用官方 .NET SDK（用于 iOS 开发）
export PATH="/usr/local/share/dotnet:$PATH"
```

保存后重新加载：

```bash
source ~/.zshrc
```

#### 步骤 4：验证安装

```bash
# 检查路径
which dotnet
# 应该输出: /usr/local/share/dotnet/dotnet

# 检查版本
dotnet --version

# 安装 iOS workload
dotnet workload install ios

# 验证 workload
dotnet workload list
```

#### 步骤 5：运行构建

```bash
./build-ios-library-simple.sh
```

---

## 📚 相关文档

我已经创建了以下文档帮助你解决这个问题：

1. **[docs/Install-Official-Dotnet-SDK.md](docs/Install-Official-Dotnet-SDK.md)**
   - 详细的官方 SDK 安装步骤
   - 环境配置指南
   - 常见问题解答

2. **[docs/iOS-Homebrew-Dotnet-Issue.md](docs/iOS-Homebrew-Dotnet-Issue.md)**
   - 问题的详细技术说明
   - 多种解决方案对比
   - Homebrew vs 官方版本的区别

3. **[docs/iOS-Build-Troubleshooting.md](docs/iOS-Build-Troubleshooting.md)**
   - 构建过程中的常见问题
   - 故障排查步骤

4. **[docs/iOS-Library-Integration.md](docs/iOS-Library-Integration.md)**
   - 构建成功后的集成指南
   - Swift/Objective-C 调用示例

---

## 🎯 快速行动清单

- [ ] 从官方网站下载 .NET 9.0 SDK
- [ ] 安装 .pkg 文件
- [ ] 编辑 `~/.zshrc` 添加 PATH 配置
- [ ] 运行 `source ~/.zshrc`
- [ ] 验证 `which dotnet` 输出正确路径
- [ ] 运行 `dotnet workload install ios`
- [ ] 运行 `./build-ios-library-simple.sh`

---

## 💡 为什么不能继续使用 Homebrew 版本？

| 需求 | Homebrew .NET | 官方 .NET |
|------|---------------|-----------|
| 构建 iOS Library | ❌ 不支持 | ✅ 支持 |
| NativeAOT 编译 | ❌ 不支持 | ✅ 支持 |
| iOS workload | ❌ 无 manifest | ✅ 完整支持 |
| Xcode 集成 | ❌ 不支持 | ✅ 支持 |
| 生成 XCFramework | ❌ 不支持 | ✅ 支持 |

**结论**：对于 iOS 开发，必须使用官方 .NET SDK。

---

## 🔄 两个版本可以共存吗？

可以！通过 PATH 环境变量控制优先级：

```bash
# 在 ~/.zshrc 中
export PATH="/usr/local/share/dotnet:$PATH"

# 这样默认使用官方版本
dotnet --version  # 官方版本

# 如果需要使用 Homebrew 版本，可以用完整路径
/opt/homebrew/bin/dotnet --version  # Homebrew 版本
```

或者设置别名：

```bash
alias dotnet-official='/usr/local/share/dotnet/dotnet'
alias dotnet-brew='/opt/homebrew/bin/dotnet'
```

---

## 📞 需要帮助？

如果在安装过程中遇到问题，请查看：
- [docs/Install-Official-Dotnet-SDK.md](docs/Install-Official-Dotnet-SDK.md) - 详细安装指南
- [docs/iOS-Homebrew-Dotnet-Issue.md](docs/iOS-Homebrew-Dotnet-Issue.md) - 技术细节说明

---

## 🎉 安装完成后

安装官方 SDK 后，你就可以：

1. ✅ 安装 iOS workload
2. ✅ 使用 NativeAOT 编译
3. ✅ 构建 iOS Library
4. ✅ 生成 XCFramework
5. ✅ 在 Xcode 项目中使用

开始构建：
```bash
./build-ios-library-simple.sh  # 简化版（仅设备）
./build-ios-library.sh         # 完整版（设备+模拟器）
```
