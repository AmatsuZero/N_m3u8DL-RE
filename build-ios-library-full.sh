#!/bin/bash
set -e

echo "=== N_m3u8DL-RE iOS Library 构建（独立项目）==="
echo ""

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
DOTNET_DIR="$PROJECT_ROOT/.dotnet"
DOTNET_BIN="$DOTNET_DIR/dotnet"

# 检查本地 .NET 是否已安装
if [ ! -f "$DOTNET_BIN" ]; then
    echo "❌ 错误: 未找到本地 .NET SDK"
    echo ""
    echo "请先运行安装脚本："
    echo "  ./setup-local-dotnet.sh"
    echo ""
    exit 1
fi

# 显示版本信息
echo "使用本地 .NET SDK:"
echo "  路径: $DOTNET_BIN"
echo "  版本: $($DOTNET_BIN --version)"
echo ""

# 项目路径
IOS_PROJECT="src/N_m3u8DL-RE.iOS/N_m3u8DL-RE.iOS.csproj"

# 检查项目文件
if [ ! -f "$IOS_PROJECT" ]; then
    echo "❌ 错误: 未找到项目文件: $IOS_PROJECT"
    exit 1
fi

# 检查 iOS workload
echo "检查 iOS workload..."
if ! "$DOTNET_BIN" workload list | grep -q "ios"; then
    echo "❌ 错误: 未安装 iOS workload"
    echo ""
    echo "请运行以下命令安装:"
    echo "  ./.dotnet/dotnet workload install ios"
    echo ""
    echo "或重新运行安装脚本:"
    echo "  ./setup-local-dotnet.sh"
    echo ""
    exit 1
fi
echo "✓ iOS workload 已安装"
echo ""

# 清理输出目录
echo "清理输出目录..."
rm -rf output/ios-library-full
mkdir -p output/ios-library-full

# 构建设备版本 (arm64)
echo ""
echo "=== 构建 iOS 库 (设备版 arm64) ==="
"$DOTNET_BIN" publish "$IOS_PROJECT" \
    -c Release \
    -r ios-arm64 \
    -p:PublishAot=true \
    -p:PublishAotUsingRuntimePack=true \
    -p:NativeLib=Shared \
    -p:SelfContained=true \
    -o output/ios-library-full/ios-arm64

echo ""
echo "=== 构建完成 ==="
echo ""

# 显示生成的文件
if [ -d "output/ios-library-full/ios-arm64" ]; then
    echo "生成的文件："
    echo ""
    echo "设备版本 (arm64):"
    ls -lh output/ios-library-full/ios-arm64/*.dylib 2>/dev/null || echo "  未找到 .dylib 文件"
    ls -lh output/ios-library-full/ios-arm64/*.h 2>/dev/null || echo "  未找到 .h 文件"
    echo ""
fi

# 检查是否生成了库文件
if [ -f "output/ios-library-full/ios-arm64/N_m3u8DL-RE.iOS.dylib" ] || \
   [ -f "output/ios-library-full/ios-arm64/libN_m3u8DL-RE.iOS.dylib" ]; then
    echo "✅ iOS Library 构建成功！"
    echo ""
    echo "输出目录: output/ios-library-full/"
    echo ""
    echo "下一步："
    echo "  1. 查看集成指南: docs/iOS-Library-Integration.md"
    echo "  2. 测试库文件"
    echo "  3. 集成到 iOS 项目"
    echo ""
else
    echo "⚠️  警告: 未找到预期的库文件"
    echo ""
    echo "请检查构建日志中的错误信息"
    echo ""
fi

echo "注意："
echo "  - 这是独立的 iOS Library 项目"
echo "  - 不依赖主项目，可以独立构建"
echo "  - 包含完整的下载功能"
echo "  - 仅包含设备版本 (arm64)"
echo ""
