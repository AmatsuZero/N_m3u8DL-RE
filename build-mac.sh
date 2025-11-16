#!/bin/bash

# N_m3u8DL-RE macOS打包脚本
# 支持Intel (x64) 和 Apple Silicon (arm64) 架构
#
# 说明：
# 1. 项目中的 `src/N_m3u8DL-RE/Directory.Build.props` 全局启用了
#    <PublishAot>true</PublishAot>（Native AOT），这会触发 .NET 的 ILCompiler
#    发布流程（Microsoft.NETCore.Native.Publish.targets）。在没有为
#    Native AOT 提供完整的 PrivateSdkAssemblies 或相应 runtime pack 时，
#    会出现类似错误：
#      "The PrivateSdkAssemblies ItemGroup is required for _ComputeAssembliesToCompileToNative"
#
# 2. 为了让本地打包在 macOS 环境下稳定运行，脚本在调用 `dotnet publish`
#    时显式覆盖 `PublishAot=false`，避免触发 Native AOT 流程。这是一个
#    安全的临时/长期方案，适合不需要 Native AOT 的发布场景。
#
# 3. 如果你想启用 Native AOT（更小体积或更快启动）：
#    - 在 CI 或脚本中传入适当的 runtime pack 与参数，例如
#      -p:PublishAot=true -p:PublishAotUsingRuntimePack=true -r <rid>
#    - 或在 `Directory.Build.props` 增加条件，使得只有在明确要求时才开启 PublishAot
#      例如使用自定义属性 `EnableNativeAot`：
#        <PublishAot Condition="'$(EnableNativeAot)' == 'true'">true</PublishAot>
#      然后在需要时通过 `-p:EnableNativeAot=true` 启用。
#
# 本脚本会覆盖 PublishAot，以避免 ILCompiler 相关错误并生成 single-file self-contained
# 可执行文件。

set -e  # 遇到错误立即退出

echo "=== N_m3u8DL-RE macOS打包脚本 ==="

# 配置参数
PROJECT_NAME="N_m3u8DL-RE"
SOLUTION_FILE="src/N_m3u8DL-RE.sln"
PROJECT_FILE="src/N_m3u8DL-RE/N_m3u8DL-RE.csproj"
BUILD_CONFIG="Release"
VERSION="0.3.0"
BUILD_DATE=$(date +%Y%m%d)

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

# 清理之前的构建输出
echo "清理之前的构建输出..."
rm -rf "artifacts"
rm -rf "publish"

# 创建输出目录
mkdir -p "artifacts"

# 构建macOS x64版本 (Intel Mac)
echo "=== 构建macOS x64版本 (Intel Mac) ==="
dotnet publish "$PROJECT_FILE" \
    -r osx-x64 \
    -c "$BUILD_CONFIG" \
    -p:PublishAot=false \
    -p:PublishSingleFile=true \
    -p:SelfContained=true \
    -o "publish/osx-x64"

# 构建macOS arm64版本 (Apple Silicon Mac)
echo "=== 构建macOS arm64版本 (Apple Silicon Mac) ==="
dotnet publish "$PROJECT_FILE" \
    -r osx-arm64 \
    -c "$BUILD_CONFIG" \
    -p:PublishAot=false \
    -p:PublishSingleFile=true \
    -p:SelfContained=true \
    -o "publish/osx-arm64"

# 创建打包文件
echo "=== 创建打包文件 ==="

# 打包x64版本
cd "publish/osx-x64"
tar -czf "../../artifacts/${PROJECT_NAME}_${VERSION}_osx-x64_${BUILD_DATE}.tar.gz" "${PROJECT_NAME}"
cd ../..

# 打包arm64版本
cd "publish/osx-arm64"
tar -czf "../../artifacts/${PROJECT_NAME}_${VERSION}_osx-arm64_${BUILD_DATE}.tar.gz" "${PROJECT_NAME}"
cd ../..

# 创建通用二进制版本 (如果支持)
echo "=== 创建通用二进制版本 ==="
if command -v lipo &> /dev/null; then
    echo "检测到lipo工具，创建通用二进制版本..."
    mkdir -p "publish/osx-universal"
    lipo -create \
        "publish/osx-x64/${PROJECT_NAME}" \
        "publish/osx-arm64/${PROJECT_NAME}" \
        -output "publish/osx-universal/${PROJECT_NAME}"
    
    cd "publish/osx-universal"
    tar -czf "../../artifacts/${PROJECT_NAME}_${VERSION}_osx-universal_${BUILD_DATE}.tar.gz" "${PROJECT_NAME}"
    cd ../..
else
    echo "警告: 未找到lipo工具，跳过通用二进制版本创建"
fi

# 创建安装脚本
echo "=== 创建安装脚本 ==="
cat > "artifacts/install.sh" << 'EOF'
#!/bin/bash
# N_m3u8DL-RE macOS安装脚本
set -e
echo "=== N_m3u8DL-RE 安装脚本 ==="
# 检测系统架构
ARCH=$(uname -m)
case "$ARCH" in
    "x86_64")
        TARGET="osx-x64"
        echo "检测到Intel架构 (x86_64)"
        ;;
    "arm64")
        TARGET="osx-arm64"
        echo "检测到Apple Silicon架构 (arm64)"
        ;;
    *)
        echo "错误: 不支持的架构: $ARCH"
        exit 1
        ;;
esac
# 查找对应的tar.gz文件
TAR_FILE=$(ls N_m3u8DL-RE_*_${TARGET}_*.tar.gz 2>/dev/null | head -1)
if [ -z "$TAR_FILE" ]; then
    echo "错误: 未找到${TARGET}架构的安装包"
    exit 1
fi
echo "找到安装包: $TAR_FILE"
# 解压安装包
echo "解压安装包..."
tar -xzf "$TAR_FILE"
# 移动可执行文件到/usr/local/bin
if [ -w "/usr/local/bin" ]; then
    echo "安装到 /usr/local/bin..."
    sudo mv "N_m3u8DL-RE" "/usr/local/bin/"
    sudo chmod +x "/usr/local/bin/N_m3u8DL-RE"
else
    echo "安装到当前目录..."
    chmod +x "N_m3u8DL-RE"
    echo "请手动将 N_m3u8DL-RE 移动到 PATH 环境变量包含的目录"
fi
echo "安装完成!"
echo "运行命令: N_m3u8DL-RE --help 查看使用说明"
EOF

chmod +x "artifacts/install.sh"

# 输出构建结果
echo ""
echo "=== 构建完成 ==="
echo "构建文件保存在 artifacts/ 目录:"
ls -la artifacts/
echo ""
echo "安装说明:"
echo "1. 下载对应的架构版本"
echo "2. 解压: tar -xzf 文件名.tar.gz"
echo "3. 运行: ./N_m3u8DL-RE --help"
echo "4. 或使用安装脚本: ./install.sh"
echo ""
echo "支持的架构:"
echo "- osx-x64: Intel Mac"
echo "- osx-arm64: Apple Silicon Mac"
if command -v lipo &> /dev/null; then
    echo "- osx-universal: 通用二进制 (同时支持Intel和Apple Silicon)"
fi