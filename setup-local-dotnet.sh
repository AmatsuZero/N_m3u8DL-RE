#!/bin/bash
set -e

echo "=== 本地 .NET SDK 自动安装脚本 ==="
echo ""

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
DOTNET_DIR="$PROJECT_ROOT/.dotnet"

# 检测系统架构
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo "✓ 检测到 Apple Silicon (M1/M2/M3)"
    DOTNET_URL="https://builds.dotnet.microsoft.com/dotnet/Sdk/9.0.307/dotnet-sdk-9.0.307-osx-arm64.tar.gz"
    ARCH_NAME="ARM64"
elif [ "$ARCH" = "x86_64" ]; then
    echo "✓ 检测到 Intel 芯片"
    DOTNET_URL="https://builds.dotnet.microsoft.com/dotnet/Sdk/9.0.307/dotnet-sdk-9.0.307-osx-x64.tar.gz"
    ARCH_NAME="x64"
else
    echo "❌ 错误: 不支持的系统架构: $ARCH"
    exit 1
fi

echo ""
echo "安装信息："
echo "  架构: $ARCH_NAME"
echo "  安装目录: $DOTNET_DIR"
echo ""

# 检查是否已经安装
if [ -d "$DOTNET_DIR" ]; then
    echo "⚠️  检测到已存在的 .dotnet 目录"
    read -p "是否删除并重新安装? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "删除旧版本..."
        rm -rf "$DOTNET_DIR"
    else
        echo "取消安装"
        exit 0
    fi
fi

# 创建目录
echo "创建安装目录..."
mkdir -p "$DOTNET_DIR"

# 下载 .NET SDK
echo ""
echo "=== 下载 .NET SDK ==="
echo "注意: 如果下载失败，请手动从以下地址下载："
echo "https://dotnet.microsoft.com/download/dotnet/9.0"
echo ""

TEMP_FILE="$PROJECT_ROOT/dotnet-sdk.tar.gz"

echo "开始下载..."
if command -v wget &> /dev/null; then
    # 使用 wget
    wget -O "$TEMP_FILE" "$DOTNET_URL" || {
        echo "❌ 下载失败"
        echo ""
        echo "请手动下载并安装："
        echo "1. 访问: https://dotnet.microsoft.com/download/dotnet/9.0"
        echo "2. 下载 'macOS $ARCH_NAME Installer' (.tar.gz 格式)"
        echo "3. 将下载的文件重命名为 dotnet-sdk.tar.gz"
        echo "4. 放在项目根目录"
        echo "5. 运行: tar -xzf dotnet-sdk.tar.gz -C .dotnet"
        exit 1
    }
elif command -v curl &> /dev/null; then
    # 使用 curl
    curl -L -o "$TEMP_FILE" "$DOTNET_URL" || {
        echo "❌ 下载失败"
        echo ""
        echo "请手动下载并安装："
        echo "1. 访问: https://dotnet.microsoft.com/download/dotnet/9.0"
        echo "2. 下载 'macOS $ARCH_NAME Installer' (.tar.gz 格式)"
        echo "3. 将下载的文件重命名为 dotnet-sdk.tar.gz"
        echo "4. 放在项目根目录"
        echo "5. 运行: tar -xzf dotnet-sdk.tar.gz -C .dotnet"
        exit 1
    }
else
    echo "❌ 错误: 未找到 wget 或 curl"
    echo ""
    echo "请手动下载并安装："
    echo "1. 访问: https://dotnet.microsoft.com/download/dotnet/9.0"
    echo "2. 下载 'macOS $ARCH_NAME Installer' (.tar.gz 格式)"
    echo "3. 将下载的文件重命名为 dotnet-sdk.tar.gz"
    echo "4. 放在项目根目录"
    echo "5. 运行: tar -xzf dotnet-sdk.tar.gz -C .dotnet"
    exit 1
fi

echo "✓ 下载完成"

# 解压
echo ""
echo "=== 解压 SDK ==="
tar -xzf "$TEMP_FILE" -C "$DOTNET_DIR"
echo "✓ 解压完成"

# 删除临时文件
rm "$TEMP_FILE"

# 验证安装
echo ""
echo "=== 验证安装 ==="
if [ -f "$DOTNET_DIR/dotnet" ]; then
    DOTNET_VERSION=$("$DOTNET_DIR/dotnet" --version)
    echo "✓ .NET SDK 安装成功"
    echo "  版本: $DOTNET_VERSION"
    echo "  路径: $DOTNET_DIR/dotnet"
else
    echo "❌ 错误: 安装失败，未找到 dotnet 可执行文件"
    exit 1
fi

# 安装 iOS workload
echo ""
echo "=== 安装 iOS Workload ==="
echo "这可能需要几分钟时间..."
"$DOTNET_DIR/dotnet" workload install ios

echo ""
echo "=== 验证 Workload ==="
"$DOTNET_DIR/dotnet" workload list

# 添加到 .gitignore
echo ""
echo "=== 更新 .gitignore ==="
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    if ! grep -q "^\.dotnet/$" "$PROJECT_ROOT/.gitignore"; then
        echo ".dotnet/" >> "$PROJECT_ROOT/.gitignore"
        echo "✓ 已添加 .dotnet/ 到 .gitignore"
    else
        echo "✓ .gitignore 已包含 .dotnet/"
    fi
else
    echo ".dotnet/" > "$PROJECT_ROOT/.gitignore"
    echo "✓ 已创建 .gitignore 并添加 .dotnet/"
fi

# 完成
echo ""
echo "=== 安装完成 ==="
echo ""
echo "✅ 本地 .NET SDK 已成功安装到: $DOTNET_DIR"
echo ""
echo "使用方式："
echo "  1. 直接使用: ./.dotnet/dotnet --version"
echo "  2. 使用构建脚本: ./build-ios-library-local.sh"
echo "  3. 临时添加到 PATH: export PATH=\"\$(pwd)/.dotnet:\$PATH\""
echo ""
echo "验证安装："
echo "  ./.dotnet/dotnet --version"
echo "  ./.dotnet/dotnet workload list"
echo ""
echo "下一步："
echo "  运行构建脚本: ./build-ios-library-local.sh"
echo ""
