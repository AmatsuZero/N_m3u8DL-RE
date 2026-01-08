#!/bin/bash

# N_m3u8DL-RE XCFramework 打包脚本
#
# 用法:
#   ./build-xcframework.sh [选项]
#
# 选项:
#   --input <目录>     库文件输入目录（默认：build/ios）
#   --output <目录>    XCFramework输出目录（默认：build/xcframework）
#   --name <名称>      框架名称（默认：M3U8DownloaderKit）
#   --clean            打包前清理输出目录
#   --help             显示帮助信息
#
# 前置条件:
#   - 已运行 build-ios.sh 生成各架构的动态库
#   - 安装了 Xcode Command Line Tools

set -e

echo "========================================="
echo "N_m3u8DL-RE XCFramework Build Script"
echo "========================================="

# 项目路径
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 默认选项
INPUT_DIR="$PROJECT_DIR/build/ios"
OUTPUT_DIR="$PROJECT_DIR/build/xcframework"
FRAMEWORK_NAME="M3U8DownloaderKit"
CLEAN_BEFORE_BUILD=false

# 动态库名称（.NET生成的库名）
LIB_NAME="N_m3u8DL-RE.Core"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --input)
            INPUT_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --name)
            FRAMEWORK_NAME="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BEFORE_BUILD=true
            shift
            ;;
        --help|-h)
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --input <目录>     库文件输入目录（默认：build/ios）"
            echo "  --output <目录>    XCFramework输出目录（默认：build/xcframework）"
            echo "  --name <名称>      框架名称（默认：M3U8DownloaderKit）"
            echo "  --clean            打包前清理输出目录"
            echo "  --help             显示此帮助信息"
            echo ""
            echo "前置条件:"
            echo "  - 已运行 build-ios.sh 生成各架构的动态库"
            echo "  - 安装了 Xcode Command Line Tools"
            echo ""
            echo "示例:"
            echo "  $0                                  # 使用默认设置"
            echo "  $0 --clean                          # 清理后重新打包"
            echo "  $0 --name MyFramework               # 自定义框架名称"
            echo ""
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# 检查输入目录
if [ ! -d "$INPUT_DIR" ]; then
    echo "错误: 输入目录不存在: $INPUT_DIR"
    echo "请先运行 build-ios.sh 生成动态库"
    exit 1
fi

# 显示配置
echo ""
echo "打包配置:"
echo "  输入目录: $INPUT_DIR"
echo "  输出目录: $OUTPUT_DIR"
echo "  框架名称: $FRAMEWORK_NAME"
echo ""

# 清理输出目录
if [ "$CLEAN_BEFORE_BUILD" = true ]; then
    echo "清理输出目录..."
    rm -rf "$OUTPUT_DIR"
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 临时目录
TEMP_DIR="$OUTPUT_DIR/temp"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# 头文件目录
HEADER_DIR="$INPUT_DIR/include"
if [ ! -d "$HEADER_DIR" ]; then
    HEADER_DIR="$PROJECT_DIR/src/N_m3u8DL-RE.Core/Interop/include"
fi

if [ ! -d "$HEADER_DIR" ]; then
    echo "错误: 头文件目录不存在"
    echo "请确保 m3u8dl.h 和 module.modulemap 文件存在"
    exit 1
fi

echo "头文件目录: $HEADER_DIR"

# 查找动态库文件
find_dynamic_lib() {
    local arch_dir="$1"
    local lib_file=""
    
    # 尝试多种可能的库名
    for name in "$LIB_NAME.dylib" "lib$LIB_NAME.dylib" "N_m3u8DL_RE_Core.dylib" "libN_m3u8DL_RE_Core.dylib"; do
        if [ -f "$arch_dir/$name" ]; then
            lib_file="$arch_dir/$name"
            break
        fi
    done
    
    # 如果没找到，搜索任何 .dylib 文件
    if [ -z "$lib_file" ]; then
        lib_file=$(find "$arch_dir" -name "*.dylib" -type f 2>/dev/null | head -1)
    fi
    
    echo "$lib_file"
}

# 创建 Framework 结构
create_framework() {
    local arch=$1
    local platform=$2  # iphoneos 或 iphonesimulator
    local dylib_path=$3
    local framework_dir="$TEMP_DIR/$arch/${FRAMEWORK_NAME}.framework"
    
    echo "创建 Framework 结构: $framework_dir"
    
    # 创建 Framework 目录结构
    mkdir -p "$framework_dir/Headers"
    mkdir -p "$framework_dir/Modules"
    
    # 复制动态库并重命名
    cp "$dylib_path" "$framework_dir/$FRAMEWORK_NAME"
    
    # 修改动态库的 install_name
    install_name_tool -id "@rpath/${FRAMEWORK_NAME}.framework/$FRAMEWORK_NAME" "$framework_dir/$FRAMEWORK_NAME"
    
    # 复制头文件
    cp "$HEADER_DIR/m3u8dl.h" "$framework_dir/Headers/"
    
    # 创建 umbrella header
    cat > "$framework_dir/Headers/${FRAMEWORK_NAME}.h" << EOF
//
//  ${FRAMEWORK_NAME}.h
//  ${FRAMEWORK_NAME}
//
//  Auto-generated umbrella header
//

#import <Foundation/Foundation.h>

//! Project version number for ${FRAMEWORK_NAME}.
FOUNDATION_EXPORT double ${FRAMEWORK_NAME}VersionNumber;

//! Project version string for ${FRAMEWORK_NAME}.
FOUNDATION_EXPORT const unsigned char ${FRAMEWORK_NAME}VersionString[];

// Public headers
#import <${FRAMEWORK_NAME}/m3u8dl.h>
EOF

    # 创建 module.modulemap
    cat > "$framework_dir/Modules/module.modulemap" << EOF
framework module ${FRAMEWORK_NAME} {
    umbrella header "${FRAMEWORK_NAME}.h"
    
    export *
    module * { export * }
}
EOF

    # 创建 Info.plist
    local min_ios_version="13.0"
    local platform_name="iPhoneOS"
    local supported_platform="iPhoneOS"
    
    if [ "$platform" = "iphonesimulator" ]; then
        platform_name="iPhoneSimulator"
        supported_platform="iPhoneSimulator"
    fi
    
    cat > "$framework_dir/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.m3u8dl.${FRAMEWORK_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>${min_ios_version}</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>${supported_platform}</string>
    </array>
</dict>
</plist>
EOF

    echo "✅ Framework 创建完成: $framework_dir"
}

# 准备各架构的库
prepare_architecture() {
    local arch=$1
    local arch_dir="$INPUT_DIR/$arch"
    local platform="iphoneos"
    
    # 确定平台
    if [[ "$arch" == *"simulator"* ]]; then
        platform="iphonesimulator"
    fi
    
    echo ""
    echo "准备架构: $arch (平台: $platform)"
    
    if [ ! -d "$arch_dir" ]; then
        echo "警告: 架构目录不存在: $arch_dir"
        return 1
    fi
    
    # 查找动态库
    local lib_file=$(find_dynamic_lib "$arch_dir")
    
    if [ -z "$lib_file" ] || [ ! -f "$lib_file" ]; then
        echo "警告: 未找到动态库文件: $arch_dir"
        ls -la "$arch_dir" 2>/dev/null || true
        return 1
    fi
    
    echo "找到动态库: $lib_file"
    
    # 创建 Framework
    create_framework "$arch" "$platform" "$lib_file"
    
    return 0
}

# 创建模拟器通用 Framework（合并arm64和x64）
create_simulator_universal_framework() {
    local sim_arm64_fw="$TEMP_DIR/iossimulator-arm64/${FRAMEWORK_NAME}.framework/$FRAMEWORK_NAME"
    local sim_x64_fw="$TEMP_DIR/iossimulator-x64/${FRAMEWORK_NAME}.framework/$FRAMEWORK_NAME"
    local output_dir="$TEMP_DIR/iossimulator-universal/${FRAMEWORK_NAME}.framework"
    
    echo ""
    echo "创建模拟器通用 Framework..."
    
    # 检查可用的模拟器库
    local available_libs=()
    [ -f "$sim_arm64_fw" ] && available_libs+=("$sim_arm64_fw")
    [ -f "$sim_x64_fw" ] && available_libs+=("$sim_x64_fw")
    
    if [ ${#available_libs[@]} -eq 0 ]; then
        echo "警告: 没有可用的模拟器库"
        return 1
    fi
    
    # 复制一个 Framework 作为基础
    local base_fw=""
    if [ -f "$sim_arm64_fw" ]; then
        base_fw="$TEMP_DIR/iossimulator-arm64/${FRAMEWORK_NAME}.framework"
    else
        base_fw="$TEMP_DIR/iossimulator-x64/${FRAMEWORK_NAME}.framework"
    fi
    
    mkdir -p "$TEMP_DIR/iossimulator-universal"
    cp -R "$base_fw" "$TEMP_DIR/iossimulator-universal/"
    
    if [ ${#available_libs[@]} -eq 1 ]; then
        echo "只有一个模拟器架构可用，直接使用..."
    else
        echo "合并模拟器架构..."
        lipo -create "${available_libs[@]}" -output "$output_dir/$FRAMEWORK_NAME"
        # 更新 install_name
        install_name_tool -id "@rpath/${FRAMEWORK_NAME}.framework/$FRAMEWORK_NAME" "$output_dir/$FRAMEWORK_NAME"
    fi
    
    echo "✅ 模拟器通用 Framework 创建完成"
    return 0
}

# 收集可用的架构
echo ""
echo "检查可用架构..."

AVAILABLE_ARCHS=()
prepare_architecture "ios-arm64" && AVAILABLE_ARCHS+=("ios-arm64")
prepare_architecture "iossimulator-arm64" && AVAILABLE_ARCHS+=("iossimulator-arm64")
prepare_architecture "iossimulator-x64" && AVAILABLE_ARCHS+=("iossimulator-x64")

if [ ${#AVAILABLE_ARCHS[@]} -eq 0 ]; then
    echo ""
    echo "错误: 没有可用的架构"
    echo "请先运行 build-ios.sh 生成动态库"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo "可用架构: ${AVAILABLE_ARCHS[*]}"

# 尝试创建模拟器通用 Framework
HAS_SIMULATOR_UNIVERSAL=false
if [[ " ${AVAILABLE_ARCHS[*]} " =~ " iossimulator-arm64 " ]] || [[ " ${AVAILABLE_ARCHS[*]} " =~ " iossimulator-x64 " ]]; then
    if create_simulator_universal_framework; then
        HAS_SIMULATOR_UNIVERSAL=true
    fi
fi

# 构建 xcodebuild 参数
echo ""
echo "创建 XCFramework..."

XCFRAMEWORK_PATH="$OUTPUT_DIR/${FRAMEWORK_NAME}.xcframework"
rm -rf "$XCFRAMEWORK_PATH"

XCODEBUILD_ARGS=(-create-xcframework)

# 添加iOS真机 Framework
if [ -d "$TEMP_DIR/ios-arm64/${FRAMEWORK_NAME}.framework" ]; then
    XCODEBUILD_ARGS+=(
        -framework "$TEMP_DIR/ios-arm64/${FRAMEWORK_NAME}.framework"
    )
fi

# 添加模拟器 Framework（优先使用通用库）
if [ "$HAS_SIMULATOR_UNIVERSAL" = true ] && [ -d "$TEMP_DIR/iossimulator-universal/${FRAMEWORK_NAME}.framework" ]; then
    XCODEBUILD_ARGS+=(
        -framework "$TEMP_DIR/iossimulator-universal/${FRAMEWORK_NAME}.framework"
    )
elif [ -d "$TEMP_DIR/iossimulator-arm64/${FRAMEWORK_NAME}.framework" ]; then
    XCODEBUILD_ARGS+=(
        -framework "$TEMP_DIR/iossimulator-arm64/${FRAMEWORK_NAME}.framework"
    )
elif [ -d "$TEMP_DIR/iossimulator-x64/${FRAMEWORK_NAME}.framework" ]; then
    XCODEBUILD_ARGS+=(
        -framework "$TEMP_DIR/iossimulator-x64/${FRAMEWORK_NAME}.framework"
    )
fi

# 添加输出路径
XCODEBUILD_ARGS+=(-output "$XCFRAMEWORK_PATH")

# 执行 xcodebuild
echo "执行: xcodebuild ${XCODEBUILD_ARGS[*]}"
xcodebuild "${XCODEBUILD_ARGS[@]}"

# 检查结果
if [ -d "$XCFRAMEWORK_PATH" ]; then
    echo ""
    echo "========================================="
    echo "✅ XCFramework 创建成功!"
    echo "========================================="
    echo ""
    echo "输出路径: $XCFRAMEWORK_PATH"
    echo ""
    echo "XCFramework 结构:"
    find "$XCFRAMEWORK_PATH" -type f | head -20
    echo ""
    
    # 显示框架信息
    if [ -f "$XCFRAMEWORK_PATH/Info.plist" ]; then
        echo "框架信息:"
        cat "$XCFRAMEWORK_PATH/Info.plist"
        echo ""
    fi
else
    echo ""
    echo "❌ XCFramework 创建失败"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 清理临时目录
rm -rf "$TEMP_DIR"

echo ""
echo "========================================="
echo "打包完成!"
echo "========================================="
echo ""
echo "XCFramework 路径: $XCFRAMEWORK_PATH"
echo ""
echo "集成步骤:"
echo "1. 将 ${FRAMEWORK_NAME}.xcframework 拖入 Xcode 项目"
echo "2. 在 General > Frameworks, Libraries 中确保设置为 'Embed & Sign'"
echo "3. 在 Swift 文件中 import ${FRAMEWORK_NAME}"
echo "4. 或在 Objective-C 中 #import <${FRAMEWORK_NAME}/m3u8dl.h>"
echo ""
echo "示例代码 (Swift):"
echo "  let instanceId = m3u8dl_init(nil)"
echo "  let result = m3u8dl_parse(instanceId, \"https://example.com/stream.m3u8\")"
echo "  // ... 使用 result"
echo "  m3u8dl_free_string(result)"
echo "  m3u8dl_dispose(instanceId)"
echo ""
