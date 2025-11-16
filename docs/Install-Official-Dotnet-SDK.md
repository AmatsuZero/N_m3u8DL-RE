# 安装官方 .NET SDK 以支持 iOS 开发

## 快速安装步骤

### 1. 下载官方 .NET SDK

访问官方下载页面：
```
https://dotnet.microsoft.com/download/dotnet/9.0
```

根据你的 Mac 芯片选择：
- **Apple Silicon (M1/M2/M3)**: 下载 "macOS Arm64 Installer"
- **Intel**: 下载 "macOS x64 Installer"

### 2. 安装 .pkg 文件

双击下载的 `.pkg` 文件，按照安装向导完成安装。

默认安装路径：`/usr/local/share/dotnet/`

### 3. 配置环境变量

编辑你的 shell 配置文件：

```bash
# 打开配置文件
nano ~/.zshrc
```

在文件末尾添加：

```bash
# 优先使用官方 .NET SDK（用于 iOS 开发）
export PATH="/usr/local/share/dotnet:$PATH"
```

保存并退出（Ctrl+O, Enter, Ctrl+X）

### 4. 应用配置

```bash
# 重新加载配置
source ~/.zshrc

# 验证 dotnet 路径
which dotnet
# 应该输出: /usr/local/share/dotnet/dotnet

# 验证版本
dotnet --version
```

### 5. 安装 iOS Workload

```bash
# 安装 iOS SDK workload
dotnet workload install ios

# 验证安装
dotnet workload list
```

应该看到类似输出：
```
Installed Workload Id      Manifest Version      Installation Source
--------------------------------------------------------------------
ios                        17.x.xxxx/9.0.100     SDK 9.0.100
```

### 6. 验证 Xcode

确保已安装 Xcode：

```bash
# 检查 Xcode 路径
xcode-select -p

# 如果未安装，从 App Store 安装 Xcode
# 然后运行：
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### 7. 运行构建脚本

```bash
# 进入项目目录
cd /Users/samzhjiang/Github/N_m3u8DL-RE

# 运行简化版构建（仅设备版）
./build-ios-library-simple.sh

# 或运行完整版构建（包含模拟器）
./build-ios-library.sh
```

---

## 常见问题

### Q: 安装后还是使用 Homebrew 版本？

A: 检查 PATH 顺序：

```bash
echo $PATH
```

确保 `/usr/local/share/dotnet` 在 Homebrew 路径之前。

### Q: 可以卸载 Homebrew 版本吗？

A: 可以，如果不再需要：

```bash
brew uninstall dotnet
```

### Q: 如何同时保留两个版本？

A: 使用别名：

```bash
# 在 ~/.zshrc 中添加
alias dotnet-official='/usr/local/share/dotnet/dotnet'
alias dotnet-brew='/opt/homebrew/bin/dotnet'

# 默认使用官方版本
export PATH="/usr/local/share/dotnet:$PATH"
```

### Q: 安装需要多少磁盘空间？

A: 约 1-2 GB（包括 SDK 和 iOS workload）

---

## 一键安装脚本（可选）

创建一个自动化安装脚本：

```bash
#!/bin/bash

echo "=== 安装官方 .NET SDK 并配置 iOS 开发环境 ==="

# 检测芯片类型
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo "检测到 Apple Silicon (M1/M2/M3)"
    SDK_URL="https://download.visualstudio.microsoft.com/download/pr/your-arm64-url"
else
    echo "检测到 Intel 芯片"
    SDK_URL="https://download.visualstudio.microsoft.com/download/pr/your-x64-url"
fi

echo ""
echo "请手动完成以下步骤："
echo "1. 访问: https://dotnet.microsoft.com/download/dotnet/9.0"
echo "2. 下载并安装对应的 .pkg 文件"
echo "3. 运行以下命令配置环境："
echo ""
echo "   echo 'export PATH=\"/usr/local/share/dotnet:\$PATH\"' >> ~/.zshrc"
echo "   source ~/.zshrc"
echo "   dotnet workload install ios"
echo ""
```

---

## 验证清单

安装完成后，运行以下命令验证：

```bash
# ✅ 1. 检查 dotnet 路径
which dotnet
# 期望: /usr/local/share/dotnet/dotnet

# ✅ 2. 检查版本
dotnet --version
# 期望: 9.0.xxx

# ✅ 3. 检查 workload
dotnet workload list
# 期望: 看到 ios workload

# ✅ 4. 检查 Xcode
xcode-select -p
# 期望: /Applications/Xcode.app/Contents/Developer

# ✅ 5. 测试构建
./build-ios-library-simple.sh
# 期望: 构建成功
```

---

## 下一步

安装完成后，请查看：
- [iOS Library 集成指南](iOS-Library-Integration.md)
- [构建故障排查](iOS-Build-Troubleshooting.md)
- [Homebrew .NET 问题说明](iOS-Homebrew-Dotnet-Issue.md)
