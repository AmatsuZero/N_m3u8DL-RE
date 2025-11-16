#!/bin/bash
# 创建iOS框架目录结构
mkdir -p output/N_m3u8DL_RE.framework
cp bin/Release/net9.0-ios/ios-arm64/publish/* output/N_m3u8DL_RE.framework/

# 生成模块映射文件
cat > output/N_m3u8DL_RE.framework/Modules/module.modulemap <<EOL
framework module N_m3u8DL_RE {
  umbrella header "N_m3u8DL_RE.h"
  export *
  module * { export * }
}
EOL

# 生成头文件
cat > output/N_m3u8DL_RE.framework/Headers/N_m3u8DL_RE.h <<EOL
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double N_m3u8DL_REVersionNumber;
FOUNDATION_EXPORT const unsigned char N_m3u8DL_REVersionString[];
EOL

# 创建xcframework
xcodebuild -create-xcframework \
  -framework output/N_m3u8DL_RE.framework \
  -output N_m3u8DL_RE.xcframework