#!/bin/bash

# N_m3u8DL-RE iOS/macOS 构建脚本
# 使用 NativeAOT + RuntimePack 方式构建原生库
# 
# 用法:
#   ./build-ios.sh [选项]
#
# 选项:
#   --arch <架构>    仅编译指定架构，可选值：
#                     ios-arm64          - iOS真机
#                     iossimulator-arm64 - iOS模拟器(Apple Silicon)
#                     iossimulator-x64   - iOS模拟器(Intel)
#                     osx-arm64          - macOS (Apple Silicon)
#                     osx-x64            - macOS (Intel)
#   --all           编译所有架构（默认）
#   --ios           仅编译iOS相关架构（真机+模拟器）
#   --macos         仅编译macOS相关架构
#   --release       Release模式（默认）
#   --debug         Debug模式
#   --clean         编译前清理输出目录
#   --help          显示帮助信息
#
# 示例:
#   ./build-ios.sh                           # 编译所有架构
#   ./build-ios.sh --arch ios-arm64          # 仅编译iOS真机架构
#   ./build-ios.sh --arch iossimulator-arm64 # 仅编译模拟器(Apple Silicon)
#   ./build-ios.sh --arch osx-arm64          # 仅编译macOS(Apple Silicon)
#   ./build-ios.sh --ios                     # 编译所有iOS架构
#   ./build-ios.sh --macos                   # 编译所有macOS架构
#   ./build-ios.sh --debug                   # Debug模式

set -e

echo "========================================="
echo "N_m3u8DL-RE iOS/macOS Build Script"
echo "========================================="\n
# 项目路径
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTNET_CMD="$PROJECT_DIR/.dotnet_local/dotnet"
CORE_PROJECT="$PROJECT_DIR/src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj"
OUTPUT_DIR="$PROJECT_DIR/build/ios"

# 默认选项
TARGET_ARCH="all"
BUILD_CONFIG="Release"
CLEAN_BEFORE_BUILD=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --arch)
            TARGET_ARCH="$2"
            shift 2
            ;;
        --all)
            TARGET_ARCH="all"
            shift
            ;;
        --release)
            BUILD_CONFIG="Release"
            shift
            ;;
        --debug)
            BUILD_CONFIG="Debug"
            shift
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
            echo "  --arch <架构>      仅编译指定架构"
            echo "                      ios-arm64          - iOS真机"
            echo "                      iossimulator-arm64 - iOS模拟器(Apple Silicon)"
            echo "                      iossimulator-x64   - iOS模拟器(Intel)"
            echo "                      osx-arm64          - macOS (Apple Silicon)"
            echo "                      osx-x64            - macOS (Intel)"
            echo "  --all             编译所有架构（默认）"
            echo "  --ios             仅编译iOS相关架构"
            echo "  --macos           仅编译macOS相关架构"
            echo "  --release         Release模式（默认）"
            echo "  --debug           Debug模式"
            echo "  --clean           编译前清理输出目录"
            echo "  --help            显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0                     # 编译所有架构"
            echo "  $0 --arch ios-arm64    # 仅编译iOS真机架构"
            echo ""
            exit 0
            ;;
        --ios)
            TARGET_ARCH="ios"
            shift
            ;;
        --macos)
            TARGET_ARCH="macos"
            shift
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# 检查dotnet是否存在
if [ ! -f "$DOTNET_CMD" ]; then
    echo "错误: 未找到本地dotnet SDK: $DOTNET_CMD"
    echo "请先运行 dotnet-install.sh 安装SDK"
    exit 1
fi

# 显示SDK版本
echo ""
echo "SDK版本:"
$DOTNET_CMD --version

# 显示构建配置
echo ""
echo "构建配置:"
echo "  目标架构: $TARGET_ARCH"
echo "  构建模式: $BUILD_CONFIG"
echo "  输出目录: $OUTPUT_DIR"
echo ""

# 清理输出目录
if [ "$CLEAN_BEFORE_BUILD" = true ] || [ "$TARGET_ARCH" = "all" ]; then
    if [ "$TARGET_ARCH" = "all" ]; then
        echo "清理输出目录..."
        rm -rf "$OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
    else
        echo "清理架构输出目录: $OUTPUT_DIR/$TARGET_ARCH"
        rm -rf "$OUTPUT_DIR/$TARGET_ARCH"
    fi
fi

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

# 构建函数 - 使用 NativeAOT + RuntimePack 方式
build_architecture() {
    local ARCH=$1
    local RID=$2
    
    echo ""
    echo "========================================="
    echo "正在编译: $ARCH"
    echo "Runtime ID: $RID"
    echo "========================================="
    
    # NativeAOT 输出目录
    local BIN_OUTPUT_DIR="$PROJECT_DIR/src/N_m3u8DL-RE.Core/bin/$BUILD_CONFIG/net9.0/$RID"
    local PUBLISH_OUTPUT_DIR="$BIN_OUTPUT_DIR/publish"
    local NATIVE_OUTPUT_DIR="$BIN_OUTPUT_DIR/native"
    
    # 构建参数 - 使用 NativeAOT + RuntimePack
    # 显式定义 IOS 常量以启用条件编译
    local BUILD_ARGS=(
        -f net9.0
        -c "$BUILD_CONFIG"
        -r "$RID"
        /p:SelfContained=true
        /p:PublishAot=true
        /p:PublishAotUsingRuntimePack=true
        /p:NativeLib=Shared
        /p:PublishTrimmed=true
        "/p:DefineConstants=IOS"
    )
    
    echo "执行: $DOTNET_CMD publish ${BUILD_ARGS[*]}"
    $DOTNET_CMD publish "$CORE_PROJECT" "${BUILD_ARGS[@]}"
    
    # 检查输出 - 查找 .dylib 动态库文件
    local FOUND_OUTPUT=""
    local FOUND_LIB=""
    
    # 查找动态库文件 (.dylib)
    for search_dir in "$NATIVE_OUTPUT_DIR" "$PUBLISH_OUTPUT_DIR" "$BIN_OUTPUT_DIR"; do
        if [ -d "$search_dir" ]; then
            local dylib=$(find "$search_dir" -maxdepth 1 -name "*.dylib" 2>/dev/null | head -1)
            if [ -n "$dylib" ]; then
                FOUND_OUTPUT="$search_dir"
                FOUND_LIB="$dylib"
                break
            fi
        fi
    done
    
    # 如果没找到 .dylib，查找 .a 静态库文件
    if [ -z "$FOUND_OUTPUT" ]; then
        for search_dir in "$NATIVE_OUTPUT_DIR" "$PUBLISH_OUTPUT_DIR" "$BIN_OUTPUT_DIR"; do
            if [ -d "$search_dir" ]; then
                local static_lib=$(find "$search_dir" -maxdepth 1 -name "*.a" 2>/dev/null | head -1)
                if [ -n "$static_lib" ]; then
                    FOUND_OUTPUT="$search_dir"
                    FOUND_LIB="$static_lib"
                    break
                fi
            fi
        done
    fi
    
    # 如果还没找到，查找 .dll 文件（备用）
    if [ -z "$FOUND_OUTPUT" ]; then
        for search_dir in "$PUBLISH_OUTPUT_DIR" "$BIN_OUTPUT_DIR"; do
            if [ -d "$search_dir" ] && [ -f "$search_dir/N_m3u8DL-RE.Core.dll" ]; then
                FOUND_OUTPUT="$search_dir"
                break
            fi
        done
    fi
    
    if [ -n "$FOUND_OUTPUT" ]; then
        echo ""
        echo "✅ $ARCH 编译完成"
        echo "源输出目录: $FOUND_OUTPUT"
        
        if [ -n "$FOUND_LIB" ]; then
            echo "原生库: $FOUND_LIB"
        fi
        
        # 复制到统一输出目录
        mkdir -p "$OUTPUT_DIR/$ARCH"
        cp -R "$FOUND_OUTPUT/"* "$OUTPUT_DIR/$ARCH/" 2>/dev/null || true
        
        echo "目标输出目录: $OUTPUT_DIR/$ARCH"
        echo ""
        echo "输出文件:"
        ls -la "$OUTPUT_DIR/$ARCH/" | head -20
    else
        echo ""
        echo "❌ $ARCH 编译失败"
        echo "检查的路径:"
        echo "  - $NATIVE_OUTPUT_DIR"
        echo "  - $PUBLISH_OUTPUT_DIR"
        echo "  - $BIN_OUTPUT_DIR"
        
        # 显示实际目录内容帮助调试
        echo ""
        echo "查找相关构建产物..."
        find "$PROJECT_DIR/src/N_m3u8DL-RE.Core/bin" -type f \( -name "*.dylib" -o -name "*.a" -o -name "*.dll" \) 2>/dev/null | head -20
        exit 1
    fi
}

# 根据目标架构执行构建
case $TARGET_ARCH in
    ios-arm64)
        build_architecture "ios-arm64" "ios-arm64"
        ;;
    iossimulator-arm64)
        build_architecture "iossimulator-arm64" "iossimulator-arm64"
        ;;
    iossimulator-x64)
        build_architecture "iossimulator-x64" "iossimulator-x64"
        ;;
    osx-arm64)
        build_architecture "osx-arm64" "osx-arm64"
        ;;
    osx-x64)
        build_architecture "osx-x64" "osx-x64"
        ;;
    ios)
        # 编译所有iOS架构（真机+模拟器）
        build_architecture "ios-arm64" "ios-arm64"
        build_architecture "iossimulator-arm64" "iossimulator-arm64"
        build_architecture "iossimulator-x64" "iossimulator-x64"
        ;;
    macos)
        # 编译所有macOS架构
        build_architecture "osx-arm64" "osx-arm64"
        build_architecture "osx-x64" "osx-x64"
        ;;
    all)
        # 编译所有架构（iOS + macOS）
        build_architecture "ios-arm64" "ios-arm64"
        build_architecture "iossimulator-arm64" "iossimulator-arm64"
        build_architecture "iossimulator-x64" "iossimulator-x64"
        build_architecture "osx-arm64" "osx-arm64"
        build_architecture "osx-x64" "osx-x64"
        ;;
    *)
        echo "错误: 未知架构 '$TARGET_ARCH'"
        echo "支持的架构: ios-arm64, iossimulator-arm64, iossimulator-x64, osx-arm64, osx-x64, ios, macos, all"
        exit 1
        ;;
esac

# 复制头文件
echo ""
echo "复制头文件..."
INCLUDE_DIR="$OUTPUT_DIR/include"
mkdir -p "$INCLUDE_DIR"
cp "$PROJECT_DIR/src/N_m3u8DL-RE.Core/Interop/include/"* "$INCLUDE_DIR/" 2>/dev/null || true

echo ""
echo "========================================="
echo "构建完成!"
echo "========================================="
echo ""
echo "输出目录: $OUTPUT_DIR"
echo ""
echo "目录结构:"
find "$OUTPUT_DIR" -type f \( -name "*.a" -o -name "*.dylib" -o -name "*.h" -o -name "*.modulemap" \) 2>/dev/null | head -20
echo ""
echo "下一步操作:"
echo "1. 检查生成的原生库 (.dylib 或 .a 文件)"
echo "2. 运行 build-xcframework.sh 创建 XCFramework"
echo ""
