#!/bin/bash

# N_m3u8DL-RE iOS构建脚本
# 用于编译iOS平台的静态库

set -e

echo "========================================="
echo "N_m3u8DL-RE iOS Build Script"
echo "========================================="

# 项目路径
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTNET_CMD="$PROJECT_DIR/.dotnet_local/dotnet"
CORE_PROJECT="$PROJECT_DIR/src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj"
OUTPUT_DIR="$PROJECT_DIR/build/ios"

# 清理输出目录
echo "Cleaning output directory..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 编译iOS arm64（真机）
echo ""
echo "Building for iOS arm64 (Device)..."
$DOTNET_CMD publish "$CORE_PROJECT" \
    -f net9.0-ios \
    -c Release \
    -r ios-arm64 \
    -o "$OUTPUT_DIR/ios-arm64" \
    /p:PublishTrimmed=true

# 编译iOS Simulator arm64
echo ""
echo "Building for iOS Simulator arm64..."
$DOTNET_CMD build "$CORE_PROJECT" \
    -f net9.0-ios \
    -c Release \
    -r iossimulator-arm64 \
    -o "$OUTPUT_DIR/iossimulator-arm64" \
    /p:PublishTrimmed=true

# 编译iOS Simulator x64（可选，用于Intel Mac）
echo ""
echo "Building for iOS Simulator x64..."
$DOTNET_CMD build "$CORE_PROJECT" \
    -f net9.0-ios \
    -c Release \
    -r iossimulator-x64 \
    -o "$OUTPUT_DIR/iossimulator-x64" \
    /p:PublishTrimmed=true

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "Output directory: $OUTPUT_DIR"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Create C exports (task-17)"
echo "2. Generate header files"
echo "3. Create XCFramework (task-20)"
