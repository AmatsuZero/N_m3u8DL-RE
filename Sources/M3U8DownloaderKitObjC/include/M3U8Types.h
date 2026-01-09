//
//  M3U8Types.h
//  M3U8DownloaderKit
//
//  数据模型类型定义
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 枚举定义

/// 日志级别
typedef NS_ENUM(NSInteger, M3U8LogLevel) {
    M3U8LogLevelDebug = 0,  ///< 调试信息
    M3U8LogLevelInfo  = 1,  ///< 一般信息
    M3U8LogLevelWarn  = 2,  ///< 警告
    M3U8LogLevelError = 3   ///< 错误
};

/// 流类型
typedef NS_ENUM(NSInteger, M3U8StreamType) {
    M3U8StreamTypeVideo = 0,    ///< 视频流
    M3U8StreamTypeAudio = 1,    ///< 音频流
    M3U8StreamTypeSubtitle = 2  ///< 字幕流
};

/// 下载状态
typedef NS_ENUM(NSInteger, M3U8DownloadStatus) {
    M3U8DownloadStatusIdle = 0,         ///< 空闲
    M3U8DownloadStatusParsing = 1,      ///< 解析中
    M3U8DownloadStatusDownloading = 2,  ///< 下载中
    M3U8DownloadStatusMerging = 3,      ///< 合并中
    M3U8DownloadStatusCompleted = 4,    ///< 已完成
    M3U8DownloadStatusFailed = 5,       ///< 失败
    M3U8DownloadStatusCancelled = 6     ///< 已取消
};

#pragma mark - 配置类

/// 下载器配置
@interface M3U8Configuration : NSObject

/// 工作线程数（默认 4）
@property (nonatomic, assign) NSInteger threadCount;

/// 连接超时（秒，默认 30）
@property (nonatomic, assign) NSTimeInterval connectionTimeout;

/// 读取超时（秒，默认 60）
@property (nonatomic, assign) NSTimeInterval readTimeout;

/// 最大重试次数（默认 3）
@property (nonatomic, assign) NSInteger maxRetryCount;

/// 临时文件目录
@property (nonatomic, copy, nullable) NSString *tempDirectory;

/// 创建默认配置
+ (instancetype)defaultConfiguration;

/// 转换为 JSON 字符串
- (nullable NSString *)toJSONString;

@end

#pragma mark - 下载选项

/// 下载选项
@interface M3U8DownloadOptions : NSObject

/// 自定义 HTTP 头
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *customHeaders;

/// 解密密钥（用于加密流）
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *decryptionKeys;

/// 自动选择最佳质量（默认 YES）
@property (nonatomic, assign) BOOL autoSelectBestQuality;

/// 选择的视频流索引（-1 表示自动选择）
@property (nonatomic, assign) NSInteger selectedVideoStreamIndex;

/// 选择的音频流索引（-1 表示自动选择）
@property (nonatomic, assign) NSInteger selectedAudioStreamIndex;

/// 创建默认选项
+ (instancetype)defaultOptions;

@end

#pragma mark - 流信息

/// 流信息
@interface M3U8StreamInfo : NSObject

/// 流类型
@property (nonatomic, assign) M3U8StreamType type;

/// 分辨率（如 "1920x1080"）
@property (nonatomic, copy, nullable) NSString *resolution;

/// 带宽（bps）
@property (nonatomic, assign) NSInteger bandwidth;

/// 编解码器
@property (nonatomic, copy, nullable) NSString *codecs;

/// 帧率
@property (nonatomic, assign) double frameRate;

/// 语言
@property (nonatomic, copy, nullable) NSString *language;

/// 名称
@property (nonatomic, copy, nullable) NSString *name;

/// 从 JSON 字典初始化
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

#pragma mark - 解析结果

/// 解析结果
@interface M3U8ParseResult : NSObject

/// 是否成功
@property (nonatomic, assign) BOOL success;

/// 错误信息
@property (nonatomic, copy, nullable) NSString *errorMessage;

/// 可用流列表
@property (nonatomic, copy) NSArray<M3U8StreamInfo *> *streams;

/// 是否为直播流
@property (nonatomic, assign) BOOL isLive;

/// 总时长（秒）
@property (nonatomic, assign) NSTimeInterval duration;

/// 从 JSON 字符串初始化
+ (nullable instancetype)parseFromJSONString:(NSString *)jsonString;

@end

#pragma mark - 下载进度

/// 下载进度
@interface M3U8DownloadProgress : NSObject

/// 进度百分比 (0-100)
@property (nonatomic, assign) NSInteger percentage;

/// 下载状态
@property (nonatomic, assign) M3U8DownloadStatus status;

/// 已下载大小（字节）
@property (nonatomic, assign) int64_t downloadedBytes;

/// 总大小（字节，可能为 0 表示未知）
@property (nonatomic, assign) int64_t totalBytes;

/// 下载速度（字节/秒）
@property (nonatomic, assign) int64_t speed;

/// 已下载分片数
@property (nonatomic, assign) NSInteger downloadedSegments;

/// 总分片数
@property (nonatomic, assign) NSInteger totalSegments;

/// 当前任务描述
@property (nonatomic, copy, nullable) NSString *currentTask;

/// 从 JSON 字符串初始化
+ (nullable instancetype)parseFromJSONString:(NSString *)jsonString;

@end

#pragma mark - 下载结果

/// 下载结果
@interface M3U8DownloadResult : NSObject

/// 是否成功
@property (nonatomic, assign) BOOL success;

/// 错误信息
@property (nonatomic, copy, nullable) NSString *errorMessage;

/// 输出文件路径
@property (nonatomic, copy, nullable) NSString *outputFile;

/// 文件大小（字节）
@property (nonatomic, assign) int64_t fileSize;

/// 下载耗时（秒）
@property (nonatomic, assign) NSTimeInterval duration;

/// 从 JSON 字符串初始化
+ (nullable instancetype)parseFromJSONString:(NSString *)jsonString;

@end

#pragma mark - 版本信息

/// 版本信息
@interface M3U8VersionInfo : NSObject

/// 库版本
@property (nonatomic, copy) NSString *version;

/// 构建日期
@property (nonatomic, copy, nullable) NSString *buildDate;

/// 支持的功能列表
@property (nonatomic, copy) NSArray<NSString *> *supportedFeatures;

/// 从 JSON 字符串初始化
+ (nullable instancetype)parseFromJSONString:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
