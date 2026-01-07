# iOS构建问题与解决方案

**日期**: 2026-01-07  
**问题**: iOS NativeAOT编译失败

---

## 问题描述

在执行 `build-ios.sh` 脚本时遇到以下错误：

```
error NETSDK1203: Ahead-of-time compilation is not supported for the target runtime identifier 'ios-arm64'.
```

## 根本原因

1. **.NET 10 对 iOS NativeAOT 的支持问题**
   - .NET 10 目前对 iOS 平台的 NativeAOT 支持存在已知问题
   - GitHub Issue: https://github.com/dotnet/sdk/issues/46790
   - 需要使用 `net10.0-ios` 目标框架而不是 `net10.0`

2. **缺少 iOS Workload**
   - 需要安装 iOS workload 才能编译 iOS 目标
   - 错误信息：`error NETSDK1147: To build this project, the following workloads must be installed: ios`

## 解决方案

### 方案1：安装 iOS Workload（推荐，但需要时间）

```bash
# 安装 iOS workload
dotnet workload install ios

# 安装完成后，启用项目文件中的 NativeAOT 配置
# 取消注释 N_m3u8DL-RE.Core.csproj 中的以下行：
# <IsAotCompatible>true</IsAotCompatible>
# <PublishAot>true</PublishAot>

# 然后运行构建脚本
./build-ios.sh
```

### 方案2：暂时禁用 NativeAOT（当前采用）

**优点**:
- 可以立即编译和测试
- 不需要安装额外的 workload
- 生成的库仍然可以在 iOS 上运行

**缺点**:
- 性能不如 NativeAOT 版本
- 体积较大（包含 JIT 运行时）
- 启动时间较长

**当前配置**:
```xml
<!-- 项目文件中暂时注释掉了 AOT 配置 -->
<!-- <IsAotCompatible>true</IsAotCompatible> -->
<!-- <PublishAot>true</PublishAot> -->
<PublishTrimmed>true</PublishTrimmed>
```

**构建脚本**:
```bash
# 移除了 /p:PublishAot=true 参数
dotnet publish -f net10.0-ios -c Release -r ios-arm64 -o output /p:PublishTrimmed=true
```

### 方案3：降级到 .NET 9（备选）

如果 .NET 10 的问题无法解决，可以考虑降级到 .NET 9：

```xml
<TargetFrameworks>net9.0;net9.0-ios</TargetFrameworks>
```

.NET 9 对 iOS NativeAOT 的支持更加成熟。

---

## 已完成的修改

### 1. 项目文件修改 (`N_m3u8DL-RE.Core.csproj`)

**修改前**:
```xml
<TargetFramework>net10.0</TargetFramework>
<PropertyGroup Condition="'$(RuntimeIdentifier)' == 'ios-arm64'...">
  <PublishAot>true</PublishAot>
  ...
</PropertyGroup>
```

**修改后**:
```xml
<TargetFrameworks>net10.0;net10.0-ios</TargetFrameworks>
<PropertyGroup Condition="$([MSBuild]::GetTargetPlatformIdentifier('$(TargetFramework)')) == 'ios'">
  <!-- <PublishAot>true</PublishAot> --> <!-- 暂时注释 -->
  <PublishTrimmed>true</PublishTrimmed>
  ...
</PropertyGroup>
```

### 2. 构建脚本修改 (`build-ios.sh`)

**修改前**:
```bash
dotnet publish "$CORE_PROJECT" \
    -c Release \
    -r ios-arm64 \
    /p:PublishAot=true \
    /p:PublishTrimmed=true
```

**修改后**:
```bash
dotnet publish "$CORE_PROJECT" \
    -f net10.0-ios \
    -c Release \
    -r ios-arm64 \
    /p:PublishTrimmed=true
```

---

## 下一步行动

### 短期（立即执行）

1. **验证当前配置是否可以编译**
   ```bash
   # 先安装 iOS workload（后台运行）
   dotnet workload install ios
   
   # 同时测试当前配置
   dotnet build src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj -f net10.0
   ```

2. **如果 workload 安装失败，继续使用方案2**
   - 编译普通的 iOS 库
   - 先完成功能开发和测试
   - 后续再优化 NativeAOT

### 中期（1-2天）

1. **等待 iOS workload 安装完成**
   - 安装可能需要较长时间（取决于网络速度）
   - 安装完成后验证是否可以启用 NativeAOT

2. **测试 NativeAOT 编译**
   ```bash
   # 取消注释项目文件中的 AOT 配置
   # 运行构建脚本
   ./build-ios.sh
   ```

3. **性能对比测试**
   - 对比 JIT 版本和 AOT 版本的性能
   - 对比启动时间和内存占用
   - 对比包体积

### 长期（1周）

1. **关注 .NET 10 iOS NativeAOT 的更新**
   - 跟踪 GitHub Issue: https://github.com/dotnet/sdk/issues/46790
   - 如果有修复，更新到最新版本

2. **考虑 .NET 9 作为备选**
   - 如果 .NET 10 问题持续存在
   - 评估降级到 .NET 9 的可行性

---

## 技术细节

### iOS 目标框架标识符

.NET 支持以下 iOS 相关的目标框架：

| 目标框架 | 说明 | 运行时标识符 |
|---------|------|-------------|
| `net10.0-ios` | iOS 应用/库 | `ios-arm64` |
| `net10.0-ios` | iOS 模拟器 | `iossimulator-arm64`, `iossimulator-x64` |
| `net10.0-maccatalyst` | Mac Catalyst | `maccatalyst-arm64`, `maccatalyst-x64` |
| `net10.0-tvos` | tvOS | `tvos-arm64` |

### NativeAOT vs JIT

| 特性 | NativeAOT | JIT |
|-----|-----------|-----|
| 启动时间 | 快 | 慢 |
| 内存占用 | 低 | 高 |
| 包体积 | 小 | 大 |
| 性能 | 高 | 中 |
| 编译时间 | 长 | 短 |
| 调试体验 | 差 | 好 |

### 当前项目状态

- ✅ 项目结构正确
- ✅ 代码编译通过（net10.0）
- ⏸️ iOS workload 安装中
- ⏸️ NativeAOT 暂时禁用
- ⏸️ iOS 编译待验证

---

## 参考资料

1. [.NET Native AOT deployment overview](https://docs.microsoft.com/en-us/dotnet/core/deploying/native-aot/)
2. [Native AOT support for iOS-like platforms](https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/ios-like-platforms/)
3. [GitHub Issue: NativeAOT broken for Apple TFMs in .NET 10](https://github.com/dotnet/sdk/issues/46790)
4. [.NET MAUI iOS Native AOT deployment](https://docs.microsoft.com/en-us/dotnet/maui/deployment/nativeaot)

---

**最后更新**: 2026-01-07 12:10  
**状态**: 问题已识别，采用方案2继续开发
