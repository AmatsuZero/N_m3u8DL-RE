/**
 * N_m3u8DL-RE iOS Native Library
 * 
 * M3U8/HLS/DASH流媒体下载库的C语言接口
 * 
 * 版本: 1.0.0
 * 平台: iOS (arm64, arm64-simulator, x64-simulator)
 * 
 * 使用说明:
 * 1. 链接静态库 libN_m3u8DL_RE_Core.a
 * 2. 调用 m3u8dl_init() 初始化下载器实例
 * 3. 调用 m3u8dl_parse() 解析M3U8 URL获取流信息
 * 4. 调用 m3u8dl_download() 或 m3u8dl_download_async() 下载
 * 5. 调用 m3u8dl_dispose() 释放资源
 * 
 * 注意事项:
 * - 所有返回的字符串指针需要使用 m3u8dl_free_string() 释放
 * - 异步操作完成后会通过回调函数通知结果
 * - 使用前请设置回调函数以接收进度和日志
 */

#ifndef M3U8DL_H
#define M3U8DL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * 类型定义
 * ============================================================================ */

/**
 * 实例ID类型
 */
typedef int32_t m3u8dl_instance_t;

/**
 * 布尔类型
 */
typedef int32_t m3u8dl_bool_t;
#define M3U8DL_TRUE  1
#define M3U8DL_FALSE 0

/**
 * 日志级别
 */
typedef enum {
    M3U8DL_LOG_DEBUG = 0,   /**< 调试信息 */
    M3U8DL_LOG_INFO  = 1,   /**< 一般信息 */
    M3U8DL_LOG_WARN  = 2,   /**< 警告 */
    M3U8DL_LOG_ERROR = 3    /**< 错误 */
} m3u8dl_log_level_t;

/**
 * 错误码
 */
typedef enum {
    M3U8DL_SUCCESS          = 0,    /**< 成功 */
    M3U8DL_ERROR_INVALID_ID = -1,   /**< 无效的实例ID */
    M3U8DL_ERROR_INVALID_PARAM = -2,/**< 无效的参数 */
    M3U8DL_ERROR_PARSE_FAILED = -3, /**< 解析失败 */
    M3U8DL_ERROR_DOWNLOAD_FAILED = -4, /**< 下载失败 */
    M3U8DL_ERROR_CANCELLED  = -5,   /**< 操作被取消 */
    M3U8DL_ERROR_INTERNAL   = -99   /**< 内部错误 */
} m3u8dl_error_t;

/* ============================================================================
 * 回调函数类型
 * ============================================================================ */

/**
 * 进度回调函数
 * 
 * @param instance_id   实例ID
 * @param percentage    进度百分比 (0-100)
 * @param status_json   JSON格式的详细状态信息
 * 
 * 状态JSON格式:
 * {
 *   "taskId": 1,
 *   "description": "Downloading segment 10/100",
 *   "currentValue": 10,
 *   "maxValue": 100,
 *   "percentage": 10.0,
 *   "speed": 1048576,
 *   "downloadedBytes": 10485760,
 *   "totalBytes": 104857600
 * }
 */
typedef void (*m3u8dl_progress_callback_t)(
    m3u8dl_instance_t instance_id,
    int32_t percentage,
    const char* status_json
);

/**
 * 日志回调函数
 * 
 * @param level     日志级别
 * @param message   日志消息
 */
typedef void (*m3u8dl_log_callback_t)(
    m3u8dl_log_level_t level,
    const char* message
);

/**
 * 完成回调函数
 * 
 * @param instance_id   实例ID
 * @param success       是否成功 (1=成功, 0=失败)
 * @param result_json   JSON格式的结果信息
 * 
 * 结果JSON格式:
 * {
 *   "success": true,
 *   "outputFile": "/path/to/output.mp4",
 *   "fileSize": 104857600,
 *   "duration": 123.45,
 *   "errorMessage": null
 * }
 */
typedef void (*m3u8dl_completion_callback_t)(
    m3u8dl_instance_t instance_id,
    m3u8dl_bool_t success,
    const char* result_json
);

/* ============================================================================
 * 初始化与释放
 * ============================================================================ */

/**
 * 初始化下载器实例
 * 
 * @param config_json   JSON格式的配置字符串（可为NULL使用默认配置）
 * @return 实例ID，失败返回-1
 * 
 * 配置JSON格式:
 * {
 *   "maxConcurrency": 8,
 *   "timeoutSeconds": 30,
 *   "retryCount": 3,
 *   "tempDirectory": "/path/to/temp",
 *   "autoCleanup": true,
 *   "customHeaders": {"User-Agent": "..."}
 * }
 * 
 * 示例:
 *   m3u8dl_instance_t id = m3u8dl_init(NULL);
 *   if (id < 0) {
 *       // 初始化失败
 *   }
 */
m3u8dl_instance_t m3u8dl_init(const char* config_json);

/**
 * 释放下载器实例
 * 
 * @param instance_id   实例ID
 * 
 * 注意: 释放前会自动取消正在进行的下载
 */
void m3u8dl_dispose(m3u8dl_instance_t instance_id);

/**
 * 释放所有下载器实例
 */
void m3u8dl_dispose_all(void);

/* ============================================================================
 * 回调设置
 * ============================================================================ */

/**
 * 设置进度回调函数
 * 
 * @param callback  回调函数指针（NULL表示禁用）
 * 
 * 建议在调用下载函数前设置
 */
void m3u8dl_set_progress_callback(m3u8dl_progress_callback_t callback);

/**
 * 设置日志回调函数
 * 
 * @param callback  回调函数指针（NULL表示禁用）
 * 
 * 建议在初始化前设置以捕获所有日志
 */
void m3u8dl_set_log_callback(m3u8dl_log_callback_t callback);

/**
 * 设置完成回调函数
 * 
 * @param callback  回调函数指针（NULL表示禁用）
 * 
 * 用于异步操作的完成通知
 */
void m3u8dl_set_completion_callback(m3u8dl_completion_callback_t callback);

/* ============================================================================
 * M3U8解析
 * ============================================================================ */

/**
 * 解析M3U8 URL，获取流信息（同步阻塞）
 * 
 * @param instance_id   实例ID
 * @param url           M3U8 URL（UTF-8编码）
 * @return JSON格式的流信息，需要使用 m3u8dl_free_string() 释放
 * 
 * 返回JSON格式:
 * {
 *   "success": true,
 *   "errorMessage": null,
 *   "streams": [
 *     {
 *       "id": "video-1",
 *       "type": "video",
 *       "codec": "avc1.640028",
 *       "bitrate": 5000000,
 *       "resolution": "1920x1080",
 *       "language": null,
 *       "isEncrypted": false
 *     },
 *     {
 *       "id": "audio-1",
 *       "type": "audio",
 *       "codec": "mp4a.40.2",
 *       "bitrate": 128000,
 *       "resolution": null,
 *       "language": "en",
 *       "isEncrypted": false
 *     }
 *   ]
 * }
 * 
 * 示例:
 *   char* result = m3u8dl_parse(id, "https://example.com/playlist.m3u8");
 *   // 处理result...
 *   m3u8dl_free_string(result);
 */
char* m3u8dl_parse(m3u8dl_instance_t instance_id, const char* url);

/**
 * 异步解析M3U8 URL（非阻塞）
 * 
 * @param instance_id   实例ID
 * @param url           M3U8 URL（UTF-8编码）
 * @return 0表示成功启动，-1表示失败
 * 
 * 结果通过完成回调函数返回
 */
int32_t m3u8dl_parse_async(m3u8dl_instance_t instance_id, const char* url);

/* ============================================================================
 * 下载功能
 * ============================================================================ */

/**
 * 开始下载（同步阻塞）
 * 
 * @param instance_id   实例ID
 * @param request_json  JSON格式的下载请求
 * @return JSON格式的下载结果，需要使用 m3u8dl_free_string() 释放
 * 
 * 请求JSON格式:
 * {
 *   "url": "https://example.com/playlist.m3u8",
 *   "outputPath": "/path/to/output.mp4",
 *   "decryptionKeys": ["kid:key"],
 *   "customHeaders": {"User-Agent": "..."},
 *   "autoSelectBestQuality": true
 * }
 * 
 * 返回JSON格式:
 * {
 *   "success": true,
 *   "outputFile": "/path/to/output.mp4",
 *   "fileSize": 104857600,
 *   "duration": 123.45,
 *   "errorMessage": null
 * }
 */
char* m3u8dl_download(m3u8dl_instance_t instance_id, const char* request_json);

/**
 * 异步下载（非阻塞）
 * 
 * @param instance_id   实例ID
 * @param request_json  JSON格式的下载请求
 * @return 0表示成功启动，-1表示失败
 * 
 * 进度通过进度回调函数返回
 * 结果通过完成回调函数返回
 */
int32_t m3u8dl_download_async(m3u8dl_instance_t instance_id, const char* request_json);

/**
 * 取消下载
 * 
 * @param instance_id   实例ID
 * 
 * 注意: 取消是异步的，实际停止可能有延迟
 */
void m3u8dl_cancel(m3u8dl_instance_t instance_id);

/* ============================================================================
 * 功能查询
 * ============================================================================ */

/**
 * 获取可用的视频处理器列表
 * 
 * @param instance_id   实例ID
 * @return JSON格式的处理器列表，需要使用 m3u8dl_free_string() 释放
 * 
 * 返回JSON格式:
 * [
 *   {"name": "BasicVideoProcessor", "priority": 0},
 *   {"name": "NativeVideoProcessor", "priority": 100}
 * ]
 */
char* m3u8dl_get_processors(m3u8dl_instance_t instance_id);

/**
 * 检查功能是否支持
 * 
 * @param instance_id   实例ID
 * @param feature       功能名称（如 "decrypt", "merge", "mux"）
 * @return 1表示支持，0表示不支持
 * 
 * 可用功能名称:
 * - "decrypt"  : 解密支持
 * - "merge"    : 文件合并
 * - "mux"      : 音视频混流
 * - "hls"      : HLS流支持
 * - "dash"     : DASH流支持
 */
m3u8dl_bool_t m3u8dl_is_feature_supported(
    m3u8dl_instance_t instance_id,
    const char* feature
);

/**
 * 获取库版本信息
 * 
 * @return JSON格式的版本信息，需要使用 m3u8dl_free_string() 释放
 * 
 * 返回JSON格式:
 * {
 *   "version": "1.0.0",
 *   "platform": "iOS",
 *   "framework": "NativeAOT",
 *   "buildDate": "2024-01-01"
 * }
 */
char* m3u8dl_get_version(void);

/* ============================================================================
 * 内存管理
 * ============================================================================ */

/**
 * 释放由本库分配的字符串内存
 * 
 * @param ptr   字符串指针
 * 
 * 注意: 仅用于释放本库返回的字符串，不要释放其他内存
 */
void m3u8dl_free_string(char* ptr);

/**
 * 分配内存
 * 
 * @param size  大小（字节）
 * @return 内存指针，失败返回NULL
 */
void* m3u8dl_alloc(int32_t size);

/**
 * 释放内存
 * 
 * @param ptr   内存指针
 */
void m3u8dl_free(void* ptr);

/* ============================================================================
 * 宏定义
 * ============================================================================ */

/**
 * 检查实例ID是否有效
 */
#define M3U8DL_IS_VALID_INSTANCE(id) ((id) > 0)

/**
 * 检查操作是否成功
 */
#define M3U8DL_SUCCEEDED(result) ((result) >= 0)

/**
 * 检查操作是否失败
 */
#define M3U8DL_FAILED(result) ((result) < 0)

#ifdef __cplusplus
}
#endif

#endif /* M3U8DL_H */
