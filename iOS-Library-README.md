# iOS Library 构建说明

本目录包含将 N_m3u8DL-RE Core 打包为 iOS Library 的相关文件。

## 📁 文件说明

- **build-ios-library.sh**: 完整版构建脚本，生成 XCFramework
- **build-ios-library-simple.sh**: 简化版构建脚本，仅构建设备版
- **docs/iOS-Library-Integration.md**: 详细的集成指南

## 🚀 快速开始

### 1. 构建 Library

```bash
# 完整版本（推荐）- 包含设备和模拟器支持
./build-ios-library.sh

# 简化版本 - 仅设备版，用于快速测试
./build-ios-library-simple.sh
```

### 2. 输出位置

- **完整版**: `output/N_m3u8DL_RE_Core.xcframework`
- **简化版**: `output/ios-library/*.dylib`

### 3. 集成到项目

将生成的 XCFramework 拖入 Xcode 项目，详见 [集成指南](docs/iOS-Library-Integration.md)

## 📋 系统要求

- macOS 12.0 或更高版本
- Xcode 14.0 或更高版本
- .NET 9.0 SDK **（必须使用官方安装版本，不支持 Homebrew 版本）**
- iOS workload（脚本会自动安装）

### ⚠️ 重要提示：不支持 Homebrew 安装的 .NET

**Homebrew 安装的 .NET SDK 不包含 iOS workload 支持！**

如果你使用 Homebrew 安装的 .NET（`brew install dotnet`），将无法构建 iOS Library。

**解决方案**：
1. 从官方网站下载并安装 .NET SDK：https://dotnet.microsoft.com/download/dotnet/9.0
2. 配置环境变量优先使用官方版本（在 `~/.zshrc` 中）：
   ```bash
   export PATH="/usr/local/share/dotnet:$PATH"
   ```
3. 重新加载配置：`source ~/.zshrc`

详细说明请查看：
- [安装官方 .NET SDK 指南](docs/Install-Official-Dotnet-SDK.md)
- [Homebrew .NET 问题说明](docs/iOS-Homebrew-Dotnet-Issue.md)

## 🔧 构建选项

### NativeAOT 编译

默认启用 NativeAOT 编译以获得最佳性能：

- ✅ 更小的包体积
- ✅ 更快的启动速度
- ✅ 原生性能

### 多架构支持

完整版构建支持以下架构：

- `ios-arm64`: iPhone/iPad 设备
- `iossimulator-arm64`: Apple Silicon Mac 模拟器
- `iossimulator-x64`: Intel Mac 模拟器

## 📚 API 文档

### 基本使用

```objective-c
// 初始化
m3u8dl_init();

// 下载
m3u8dl_download("https://example.com/playlist.m3u8", 
                "/path/to/output.mp4", 
                completion_callback);

// 获取进度
int progress = m3u8dl_get_progress();

// 取消
m3u8dl_cancel();
```

完整 API 参考请查看 [集成指南](docs/iOS-Library-Integration.md)

## 🐛 故障排除

### 构建失败

1. 确保已安装 .NET 9.0 SDK
2. 运行 `dotnet workload list` 检查 workload
3. 清理输出目录：`rm -rf output`

### 集成问题

1. 检查 Framework Search Paths
2. 确保 XCFramework 已正确嵌入
3. 查看 Xcode 控制台日志

## 📖 更多文档

- [架构说明](ARCHITECTURE.md)
- [重构文档](REFACTORING.md)
- [iOS 集成指南](docs/iOS-Library-Integration.md)

## 📄 许可证

遵循项目原有许可证。
