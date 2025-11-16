#!/bin/bash
set -e

echo "=== N_m3u8DL-RE Core iOS Library 构建脚本 ==="

# 配置
PROJECT_NAME="N_m3u8DL_RE_Core"
CORE_PROJECT="src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj"
OUTPUT_DIR="output"
FRAMEWORK_NAME="${PROJECT_NAME}.framework"

# 清理旧的输出
echo "清理旧的输出目录..."
rm -rf ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}

# 检查 .NET SDK
echo "检查 .NET SDK..."
if ! command -v dotnet &> /dev/null; then
    echo "错误: 未安装 .NET SDK"
    echo "请从 https://dotnet.microsoft.com/download 安装 .NET 9.0 SDK"
    exit 1
fi

DOTNET_PATH=$(which dotnet)
echo "当前 .NET 版本: $(dotnet --version)"
echo "dotnet 路径: $DOTNET_PATH"

# 检查是否使用 Homebrew 安装的 .NET
if [[ "$DOTNET_PATH" == *"homebrew"* ]] || [[ "$DOTNET_PATH" == *"/opt/homebrew/"* ]]; then
    echo ""
    echo "⚠️  警告: 检测到使用 Homebrew 安装的 .NET SDK"
    echo "⚠️  Homebrew 版本的 .NET 不支持 iOS workload！"
    echo ""
    echo "解决方案："
    echo "1. 从官方网站下载并安装 .NET SDK:"
    echo "   https://dotnet.microsoft.com/download/dotnet/9.0"
    echo ""
    echo "2. 安装后，将官方版本路径添加到 PATH（在 ~/.zshrc 中）："
    echo "   export PATH=\"/usr/local/share/dotnet:\$PATH\""
    echo ""
    echo "3. 重新加载配置："
    echo "   source ~/.zshrc"
    echo ""
    echo "详细说明请查看: docs/iOS-Homebrew-Dotnet-Issue.md"
    echo ""
    exit 1
fi

# 检查并安装 workload
echo "检查 iOS workload..."

# 检查并安装 microsoft-net-sdk-ios workload
if ! dotnet workload list | grep -q "microsoft-net-sdk-ios"; then
    echo "安装 microsoft-net-sdk-ios workload..."
    dotnet workload install microsoft-net-sdk-ios
    echo "microsoft-net-sdk-ios workload 安装完成"
else
    echo "microsoft-net-sdk-ios workload 已安装"
fi

# 检查并安装 mobile-librarybuilder workload
if ! dotnet workload list | grep -q "mobile-librarybuilder"; then
    echo "安装 mobile-librarybuilder workload..."
    dotnet workload install mobile-librarybuilder
    echo "mobile-librarybuilder workload 安装完成"
else
    echo "mobile-librarybuilder workload 已安装"
fi

# 构建 iOS 设备版本 (arm64)
echo ""
echo "=== 构建 iOS 设备版本 (arm64) ==="
dotnet publish ${CORE_PROJECT} \
    -c Release \
    -f net9.0-ios \
    -r ios-arm64 \
    -p:PublishAot=true \
    -p:PublishAotUsingRuntimePack=true \
    -p:NativeLib=Shared \
    -p:SelfContained=true \
    -o ${OUTPUT_DIR}/ios-arm64

# 构建 iOS 模拟器版本 (arm64)
echo ""
echo "=== 构建 iOS 模拟器版本 (arm64) ==="
dotnet publish ${CORE_PROJECT} \
    -c Release \
    -f net9.0-ios \
    -r iossimulator-arm64 \
    -p:PublishAot=true \
    -p:PublishAotUsingRuntimePack=true \
    -p:NativeLib=Shared \
    -p:SelfContained=true \
    -o ${OUTPUT_DIR}/iossimulator-arm64

# 构建 iOS 模拟器版本 (x64)
echo ""
echo "=== 构建 iOS 模拟器版本 (x64) ==="
dotnet publish ${CORE_PROJECT} \
    -c Release \
    -f net9.0-ios \
    -r iossimulator-x64 \
    -p:PublishAot=true \
    -p:PublishAotUsingRuntimePack=true \
    -p:NativeLib=Shared \
    -p:SelfContained=true \
    -o ${OUTPUT_DIR}/iossimulator-x64

# 创建 Framework 目录结构
echo ""
echo "=== 创建 Framework 结构 ==="

# 设备版 Framework
DEVICE_FRAMEWORK="${OUTPUT_DIR}/device/${FRAMEWORK_NAME}"
mkdir -p ${DEVICE_FRAMEWORK}/Headers
mkdir -p ${DEVICE_FRAMEWORK}/Modules

# 模拟器版 Framework (合并 arm64 和 x64)
SIMULATOR_FRAMEWORK="${OUTPUT_DIR}/simulator/${FRAMEWORK_NAME}"
mkdir -p ${SIMULATOR_FRAMEWORK}/Headers
mkdir -p ${SIMULATOR_FRAMEWORK}/Modules

# 查找生成的动态库文件
DEVICE_LIB=$(find ${OUTPUT_DIR}/ios-arm64 -name "*.dylib" | head -n 1)
SIMULATOR_ARM64_LIB=$(find ${OUTPUT_DIR}/iossimulator-arm64 -name "*.dylib" | head -n 1)
SIMULATOR_X64_LIB=$(find ${OUTPUT_DIR}/iossimulator-x64 -name "*.dylib" | head -n 1)

if [ -z "$DEVICE_LIB" ]; then
    echo "错误: 未找到设备版动态库"
    exit 1
fi

echo "找到设备版库: $DEVICE_LIB"
echo "找到模拟器 arm64 库: $SIMULATOR_ARM64_LIB"
echo "找到模拟器 x64 库: $SIMULATOR_X64_LIB"

# 复制设备版库
cp ${DEVICE_LIB} ${DEVICE_FRAMEWORK}/${PROJECT_NAME}

# 创建模拟器通用库 (合并 arm64 和 x64)
echo "创建模拟器通用库..."
lipo -create \
    ${SIMULATOR_ARM64_LIB} \
    ${SIMULATOR_X64_LIB} \
    -output ${SIMULATOR_FRAMEWORK}/${PROJECT_NAME}

# 生成头文件
echo "生成头文件..."
cat > ${DEVICE_FRAMEWORK}/Headers/${PROJECT_NAME}.h <<EOL
#ifndef ${PROJECT_NAME}_h
#define ${PROJECT_NAME}_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// API 版本
#define M3U8DL_API_VERSION_MAJOR 1
#define M3U8DL_API_VERSION_MINOR 0
#define M3U8DL_API_VERSION_PATCH 0

// 回调函数类型
typedef void (*m3u8dl_progress_callback)(int progress, long long downloaded_bytes, long long total_bytes);
typedef void (*m3u8dl_completion_callback)(int result, const char* output_path);

// 初始化库
int m3u8dl_init(void);

// 设置进度回调
void m3u8dl_set_progress_callback(m3u8dl_progress_callback callback);

// 开始下载
int m3u8dl_download(const char* url, const char* output_path, m3u8dl_completion_callback callback);

// 获取下载进度 (0-100)
int m3u8dl_get_progress(void);

// 取消下载
int m3u8dl_cancel(void);

// 获取版本信息
const char* m3u8dl_get_version(void);

// 释放字符串内存
void m3u8dl_free_string(const char* str);

// 获取API版本号
int m3u8dl_get_api_version(void);

#ifdef __cplusplus
}
#endif

#endif /* ${PROJECT_NAME}_h */
EOL

# 复制头文件到模拟器版
cp ${DEVICE_FRAMEWORK}/Headers/${PROJECT_NAME}.h ${SIMULATOR_FRAMEWORK}/Headers/

# 生成 module.modulemap
echo "生成 module.modulemap..."
cat > ${DEVICE_FRAMEWORK}/Modules/module.modulemap <<EOL
framework module ${PROJECT_NAME} {
    umbrella header "${PROJECT_NAME}.h"
    export *
    module * { export * }
}
EOL

cp ${DEVICE_FRAMEWORK}/Modules/module.modulemap ${SIMULATOR_FRAMEWORK}/Modules/

# 生成 Info.plist
echo "生成 Info.plist..."
cat > ${DEVICE_FRAMEWORK}/Info.plist <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${PROJECT_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.n-m3u8dl-re.core</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${PROJECT_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>0.5.1</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOL

cp ${DEVICE_FRAMEWORK}/Info.plist ${SIMULATOR_FRAMEWORK}/

# 创建 XCFramework
echo ""
echo "=== 创建 XCFramework ==="
xcodebuild -create-xcframework \
    -framework ${DEVICE_FRAMEWORK} \
    -framework ${SIMULATOR_FRAMEWORK} \
    -output ${OUTPUT_DIR}/${PROJECT_NAME}.xcframework

echo ""
echo "=== 构建完成 ==="
echo "XCFramework 位置: ${OUTPUT_DIR}/${PROJECT_NAME}.xcframework"
echo ""
echo "使用方法："
echo "1. 将 ${PROJECT_NAME}.xcframework 拖入 Xcode 项目"
echo "2. 在 Build Settings 中添加 Framework Search Paths"
echo "3. 在代码中 #import <${PROJECT_NAME}/${PROJECT_NAME}.h>"
echo "4. 调用导出的 C 函数"
echo ""
echo "示例代码："
echo "  m3u8dl_init();"
echo "  m3u8dl_download(\"https://example.com/playlist.m3u8\", \"/path/to/output\", callback);"
