#!/bin/bash
set -e

echo "=== N_m3u8DL-RE Core iOS Library 简化构建 ==="

CORE_PROJECT="src/N_m3u8DL-RE.Core/N_m3u8DL-RE.Core.csproj"

# 检查环境
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

# 安装 workload
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

# 清理输出目录
echo "清理输出目录..."
rm -rf output/ios-library
mkdir -p output/ios-library

# 构建 iOS 库
echo ""
echo "=== 构建 iOS 库 (仅设备版 arm64) ==="
dotnet publish ${CORE_PROJECT} \
    -c Release \
    -f net9.0-ios \
    -r ios-arm64 \
    -p:PublishAot=true \
    -p:PublishAotUsingRuntimePack=true \
    -p:NativeLib=Shared \
    -p:SelfContained=true \
    -o output/ios-library

echo ""
echo "=== 构建完成 ==="
echo "输出目录: output/ios-library"
echo ""
echo "生成的文件："
ls -lh output/ios-library/*.dylib 2>/dev/null || echo "  (动态库文件)"
echo ""
echo "注意: 这是简化版本，仅包含设备版本 (arm64)"
echo "如需完整的 XCFramework (包含模拟器支持)，请使用: ./build-ios-library.sh"
