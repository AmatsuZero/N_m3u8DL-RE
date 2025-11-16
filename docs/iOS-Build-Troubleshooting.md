# iOS Library 构建故障排查

本文档列出了构建 iOS Library 时可能遇到的常见问题及解决方案。

## 问题 1: NETSDK1139 - iOS 平台标识符无法识别

### 错误信息
```
error NETSDK1139: The target platform identifier ios was not recognized.
```

### 原因
.NET SDK 缺少 iOS workload 支持。

### 解决方案

#### 方案 1: 安装 iOS workload（推荐）
```bash
dotnet workload install microsoft-net-sdk-ios
```

#### 方案 2: 同时安装 iOS 和 mobile-librarybuilder
```bash
dotnet workload install microsoft-net-sdk-ios
dotnet workload install mobile-librarybuilder
```

**注意**: 在 .NET 9.0 中，iOS workload 的正确名称是 `microsoft-net-sdk-ios`，而不是 `ios`。

#### 方案 3: 更新所有 workload
```bash
dotnet workload update
```

### 验证安装
```bash
dotnet workload list
```

应该看到类似输出：
```
Installed Workload Id      Manifest Version      Installation Source
--------------------------------------------------------------------
microsoft-net-sdk-ios      17.x.xxxx/9.0.100     SDK 9.0.100
mobile-librarybuilder      9.0.11/9.0.100        SDK 9.0.100
```

---

## 问题 2: 找不到 .NET SDK

### 错误信息
```
错误: 未安装 .NET SDK
```

### 解决方案
从官方网站下载并安装 .NET 9.0 SDK：
https://dotnet.microsoft.com/download/dotnet/9.0

### 验证安装
```bash
dotnet --version
```

应该显示 9.0.x 版本。

---

## 问题 3: 构建失败 - 找不到动态库

### 错误信息
```
错误: 未找到设备版动态库
```

### 原因
NativeAOT 编译失败或输出目录不正确。

### 解决方案

1. **检查项目配置**
   确保 `N_m3u8DL-RE.Core.csproj` 包含以下配置：
   ```xml
   <PublishAot Condition="'$(TargetFramework)' == 'net9.0-ios'">true</PublishAot>
   <NativeLib Condition="'$(TargetFramework)' == 'net9.0-ios'">Shared</NativeLib>
   ```

2. **清理并重新构建**
   ```bash
   rm -rf output
   dotnet clean src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj
   ./build-ios-library.sh
   ```

3. **检查构建日志**
   查看详细的错误信息：
   ```bash
   dotnet publish src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj \
       -c Release \
       -f net9.0-ios \
       -r ios-arm64 \
       -p:PublishAot=true \
       -p:NativeLib=Shared \
       -v detailed
   ```

---

## 问题 4: Xcode 找不到 Framework

### 错误信息
在 Xcode 中编译时提示找不到 Framework。

### 解决方案

1. **检查 Framework Search Paths**
   - 打开 Xcode 项目
   - 选择 Target → Build Settings
   - 搜索 "Framework Search Paths"
   - 添加 XCFramework 所在目录

2. **确保 Framework 已嵌入**
   - 选择 Target → General
   - 在 "Frameworks, Libraries, and Embedded Content" 中
   - 确保 XCFramework 的 Embed 选项为 "Embed & Sign"

3. **清理 Xcode 缓存**
   ```
   Product → Clean Build Folder (Shift + Cmd + K)
   ```

---

## 问题 5: 运行时崩溃

### 错误信息
应用启动或调用 API 时崩溃。

### 解决方案

1. **确保已初始化**
   在调用其他 API 前必须先调用：
   ```objective-c
   m3u8dl_init();
   ```

2. **检查参数有效性**
   确保传递的字符串指针不为 NULL：
   ```objective-c
   const char *url = [urlString UTF8String];
   if (url != NULL) {
       m3u8dl_download(url, ...);
   }
   ```

3. **查看崩溃日志**
   在 Xcode 中查看详细的崩溃堆栈。

---

## 问题 6: NativeAOT 编译错误

### 错误信息
```
ILC: Method ... not found
```

### 原因
某些代码使用了 NativeAOT 不支持的特性（如反射）。

### 解决方案

1. **避免使用反射**
   使用源生成器替代反射。

2. **保留必要的类型**
   在 `.csproj` 中添加：
   ```xml
   <ItemGroup>
     <TrimmerRootAssembly Include="AssemblyName" />
   </ItemGroup>
   ```

3. **禁用 AOT（临时方案）**
   如果需要快速测试，可以暂时禁用 AOT：
   ```bash
   dotnet publish ... -p:PublishAot=false
   ```

---

## 问题 7: 模拟器构建失败

### 错误信息
模拟器版本构建失败。

### 解决方案

1. **仅构建设备版**
   使用简化版脚本：
   ```bash
   ./build-ios-library-simple.sh
   ```

2. **检查 Xcode 版本**
   确保 Xcode 版本 ≥ 14.0：
   ```bash
   xcodebuild -version
   ```

3. **更新 Command Line Tools**
   ```bash
   xcode-select --install
   ```

---

## 问题 8: lipo 命令失败

### 错误信息
```
fatal error: /Applications/Xcode.app/.../lipo: ...
```

### 原因
Xcode Command Line Tools 未正确安装。

### 解决方案

1. **安装 Command Line Tools**
   ```bash
   xcode-select --install
   ```

2. **设置正确的 Xcode 路径**
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```

3. **验证安装**
   ```bash
   which lipo
   lipo -info /usr/bin/lipo
   ```

---

## 问题 9: 权限错误

### 错误信息
```
Permission denied
```

### 解决方案

1. **添加执行权限**
   ```bash
   chmod +x build-ios-library.sh
   chmod +x build-ios-library-simple.sh
   ```

2. **检查输出目录权限**
   ```bash
   ls -la output/
   ```

---

## 问题 10: 依赖项冲突

### 错误信息
```
error NU1107: Version conflict detected
```

### 解决方案

1. **清理 NuGet 缓存**
   ```bash
   dotnet nuget locals all --clear
   ```

2. **删除 bin 和 obj 目录**
   ```bash
   find . -name "bin" -o -name "obj" | xargs rm -rf
   ```

3. **重新恢复依赖**
   ```bash
   dotnet restore src/N_m3u8DL-RE.sln --force
   ```

---

## 调试技巧

### 1. 启用详细日志
```bash
dotnet publish ... -v detailed > build.log 2>&1
```

### 2. 检查生成的文件
```bash
find output/ -name "*.dylib" -o -name "*.a"
ls -lh output/ios-arm64/
```

### 3. 验证 Framework 结构
```bash
tree output/device/N_m3u8DL_RE_Core.framework
```

### 4. 检查符号导出
```bash
nm -g output/ios-arm64/*.dylib | grep m3u8dl
```

### 5. 验证架构
```bash
lipo -info output/device/N_m3u8DL_RE_Core.framework/N_m3u8DL_RE_Core
```

---

## 获取帮助

如果以上方案都无法解决问题：

1. **查看完整构建日志**
   ```bash
   ./build-ios-library.sh 2>&1 | tee build.log
   ```

2. **检查系统环境**
   ```bash
   dotnet --info
   xcodebuild -version
   sw_vers
   ```

3. **提交 Issue**
   在 GitHub 上提交 Issue，附上：
   - 错误信息
   - 构建日志
   - 系统信息
   - 重现步骤

---

## 相关文档

- [iOS Library 集成指南](iOS-Library-Integration.md)
- [构建脚本说明](../iOS-Library-README.md)
- [架构文档](../ARCHITECTURE.md)

---

**最后更新**: 2025-11-16
