# N_m3u8DL-RE macOS打包指南

## 概述

本文档介绍如何在macOS平台上打包N_m3u8DL-RE命令行工具。打包脚本支持Intel (x64) 和 Apple Silicon (arm64) 两种架构。

## 系统要求

- macOS 10.15 (Catalina) 或更高版本
- .NET 9.0 SDK
- 至少2GB可用磁盘空间

## 安装依赖

### 1. 安装.NET SDK

```bash
# 使用Homebrew安装
brew install dotnet-sdk

# 或从官网下载安装包
# https://dotnet.microsoft.com/download/dotnet/9.0
```

### 2. 验证安装

```bash
dotnet --version
# 应该输出: 9.0.x
```

## 使用打包脚本

### 基本用法

```bash
# 运行打包脚本
./build-mac.sh
```

### 脚本功能

打包脚本会自动：
1. 检查.NET SDK安装
2. 清理之前的构建输出
3. 构建macOS x64版本 (Intel Mac)
4. 构建macOS arm64版本 (Apple Silicon Mac)
5. 创建通用二进制版本 (如果可用)
6. 生成安装脚本
7. 打包成tar.gz格式

### 输出文件

构建完成后，所有文件将保存在 `artifacts/` 目录：

```
artifacts/
├── N_m3u8DL-RE_0.3.0_osx-x64_20251021.tar.gz      # Intel版本
├── N_m3u8DL-RE_0.3.0_osx-arm64_20251021.tar.gz    # Apple Silicon版本
├── N_m3u8DL-RE_0.3.0_osx-universal_20251021.tar.gz # 通用二进制版本
└── install.sh                                     # 安装脚本
```

## 安装和使用

### 方法1: 使用安装脚本

```bash
cd artifacts/
./install.sh
```

安装脚本会自动：
- 检测系统架构
- 选择正确的版本
- 安装到系统PATH

### 方法2: 手动安装

```bash
# 解压对应架构的包
tar -xzf N_m3u8DL-RE_0.3.0_osx-x64_20251021.tar.gz

# 运行程序
./N_m3u8DL-RE --help

# 或安装到系统路径
sudo mv N_m3u8DL-RE /usr/local/bin/
N_m3u8DL-RE --help
```

## 构建选项

### 自定义版本号

编辑 `build-mac.sh` 文件中的 `VERSION` 变量：

```bash
VERSION="1.0.0"  # 修改为需要的版本号
```

### 自定义构建配置

修改 `BUILD_CONFIG` 变量：

```bash
BUILD_CONFIG="Debug"  # 调试版本
BUILD_CONFIG="Release" # 发布版本（默认）
```

## 高级用法

### 仅构建特定架构

如果需要仅构建特定架构，可以修改脚本或直接使用dotnet命令：

```bash
# 仅构建Intel版本
dotnet publish src/N_m3u8DL-RE/N_m3u8DL-RE.csproj \
    -r osx-x64 \
    -c Release \
    -p:PublishSingleFile=true \
    -p:SelfContained=true \
    -o publish/osx-x64

# 仅构建Apple Silicon版本
dotnet publish src/N_m3u8DL-RE/N_m3u8DL-RE.csproj \
    -r osx-arm64 \
    -c Release \
    -p:PublishSingleFile=true \
    -p:SelfContained=true \
    -o publish/osx-arm64
```

### 创建DMG安装包（可选）

如果需要创建macOS标准的DMG安装包，可以使用以下工具：

```bash
# 安装create-dmg
brew install create-dmg

# 创建DMG包
create-dmg \
  --volname "N_m3u8DL-RE" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "N_m3u8DL-RE" 200 190 \
  --hide-extension "N_m3u8DL-RE" \
  --app-drop-link 600 185 \
  "N_m3u8DL-RE.dmg" \
  "publish/osx-universal/"
```

## 故障排除

### 常见问题

1. **错误: 未安装.NET SDK**
   - 解决方案: 安装.NET 9.0 SDK

2. **权限被拒绝**
   - 解决方案: `chmod +x build-mac.sh`

3. **构建失败**
   - ���查网络连接
   - 清理nuget缓存: `dotnet nuget locals all --clear`

### 调试构建

```bash
# 启用详细输出
./build-mac.sh 2>&1 | tee build.log

# 或使用调试配置
BUILD_CONFIG="Debug" ./build-mac.sh
```

## 集成到CI/CD

可以将此脚本集成到GitHub Actions等CI/CD平台：

```yaml
# .github/workflows/build-mac.yml
name: Build macOS

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-mac:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: 9.0.x
    
    - name: Build and Package
      run: |
        chmod +x build-mac.sh
        ./build-mac.sh
    
    - name: Upload Artifacts
      uses: actions/upload-artifact@v3
      with:
        name: macos-binaries
        path: artifacts/
```

## 版本管理

建议使用语义化版本控制：

- 主版本号：不兼容的API修改
- 次版本号：向后兼容的功能性新增
- 修订号：向后兼容的问题修正

## 联系方式

如有问题，请参考：
- 项目README.md
- GitHub Issues
- 项目文档