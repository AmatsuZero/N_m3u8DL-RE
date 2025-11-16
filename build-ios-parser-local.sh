#!/bin/bash
set -e

echo "=== N_m3u8DL-RE Parser iOS Library 构建（使用本地 .NET） ==="
echo ""
echo "注意：这是临时方案，仅构建 Parser 库（解析功能）"
echo "完整的下载功能需要解决依赖问题后才能构建"
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
PARSER_PROJECT="src/N_m3u8DL-RE.Parser/N_m3u8DL-RE.Parser.csproj"

# 检查项目文件
if [ ! -f "$PARSER_PROJECT" ]; then
    echo "❌ 错误: 未找到项目文件: $PARSER_PROJECT"
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
rm -rf output/ios-parser
mkdir -p output/ios-parser

# 构建 iOS 库（仅设备版）
echo ""
echo "=== 构建 iOS Parser 库 (设备版 arm64) ==="
"$DOTNET_BIN" publish "$PARSER_PROJECT" \
    -c Release \
    -f net9.0-ios \
    -r ios-arm64 \
    -p:PublishAot=true \
    -p:PublishAotUsingRuntimePack=true \
    -p:NativeLib=Shared \
    -p:SelfContained=true \
    -o output/ios-parser

echo ""
echo "=== 构建完成 ==="
echo ""
echo "输出目录: output/ios-parser"
echo ""

# 显示生成的文件
if [ -d "output/ios-parser" ]; then
    echo "生成的文件："
    ls -lh output/ios-parser/*.dylib 2>/dev/null || echo "  未找到 .dylib 文件"
    ls -lh output/ios-parser/*.h 2>/dev/null || echo "  未找到 .h 文件"
    echo ""
fi

echo "注意："
echo "  - 这是 Parser 库，仅包含解析功能"
echo "  - 不包含下载功能（需要解决依赖问题）"
echo "  - 仅包含设备版本 (arm64)"
echo ""
echo "下一步："
echo "  1. 查看问题分析: docs/iOS-Library-Build-Issue.md"
echo "  2. 选择合适的解决方案"
echo "  3. 实现完整的 iOS Library"
echo ""
