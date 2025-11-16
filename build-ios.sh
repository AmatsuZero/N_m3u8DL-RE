#!/bin/bash
set -e  # 遇到错误立即退出

echo "=== N_m3u8DL-RE iOS构建脚本 ==="

# 检查是否安装了.NET SDK
echo "检查.NET SDK安装..."
if ! command -v dotnet &> /dev/null; then
    echo "错误: 未安装.NET SDK"
    echo "请从 https://dotnet.microsoft.com/download 安装.NET 9.0 SDK"
    exit 1
fi

# 检查.NET版本
echo "检查.NET版本..."
DOTNET_VERSION=$(dotnet --version)
echo "当前.NET版本: $DOTNET_VERSION"

# 检查并安装所需的workload
echo "检查iOS开发所需的workload..."

# 检查是否已安装 mobile-librarybuilder workload
if ! dotnet workload list | grep -q "mobile-librarybuilder"; then
    echo "未检测到 mobile-librarybuilder workload，正在安装..."
    dotnet workload install mobile-librarybuilder
    echo "mobile-librarybuilder workload 安装完成"
else
    echo "mobile-librarybuilder workload 已安装"
fi

# 注意：.NET 9.0 中不需要单独安装 ios workload
# mobile-librarybuilder 已经包含了 iOS 构建所需的功能

# 恢复项目依赖（禁用AOT以支持iOS）
echo "恢复项目依赖..."
dotnet restore src/N_m3u8DL-RE.sln \
    -r ios-arm64 \
    -p:PublishAot=false

# 构建iOS版本（移除AOT编译选项）
echo "=== 开始构建iOS版本 ==="
dotnet publish src/N_m3u8DL-RE.sln \
    -c Release \
    -r ios-arm64 \
    -p:PublishAot=false \
    -p:PublishSingleFile=true \
    --self-contained true

echo ""
echo "=== 构建完成 ==="
echo "输出目录: src/N_m3u8DL-RE/bin/Release/net9.0-ios/ios-arm64/publish/"