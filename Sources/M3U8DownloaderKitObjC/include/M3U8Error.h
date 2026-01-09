//
//  M3U8Error.h
//  M3U8DownloaderKit
//
//  错误定义
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// M3U8DownloaderKit 错误域
FOUNDATION_EXPORT NSErrorDomain const M3U8ErrorDomain;

/// 错误码
typedef NS_ERROR_ENUM(M3U8ErrorDomain, M3U8ErrorCode) {
    /// 初始化失败
    M3U8ErrorCodeInitializationFailed = 1000,
    
    /// 实例已释放
    M3U8ErrorCodeDisposed = 1001,
    
    /// 无效参数
    M3U8ErrorCodeInvalidParameter = 1002,
    
    /// 解析失败
    M3U8ErrorCodeParseFailed = 2000,
    
    /// 下载失败
    M3U8ErrorCodeDownloadFailed = 3000,
    
    /// 下载被取消
    M3U8ErrorCodeCancelled = 3001,
    
    /// 网络错误
    M3U8ErrorCodeNetworkError = 4000,
    
    /// 文件操作错误
    M3U8ErrorCodeFileError = 5000,
    
    /// JSON 解析错误
    M3U8ErrorCodeJSONError = 6000,
    
    /// 内部错误
    M3U8ErrorCodeInternalError = 9999
};

/// 创建 M3U8 错误的辅助函数
NS_INLINE NSError *M3U8ErrorMake(M3U8ErrorCode code, NSString * _Nullable reason) {
    NSDictionary *userInfo = nil;
    if (reason) {
        userInfo = @{ NSLocalizedDescriptionKey: reason };
    }
    return [NSError errorWithDomain:M3U8ErrorDomain code:code userInfo:userInfo];
}

NS_ASSUME_NONNULL_END
