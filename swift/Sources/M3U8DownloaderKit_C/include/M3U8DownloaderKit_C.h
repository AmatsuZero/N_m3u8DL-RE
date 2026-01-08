//
//  M3U8DownloaderKit_C.h
//  M3U8DownloaderKit
//
//  C 桥接头文件
//

#ifndef M3U8DownloaderKit_C_h
#define M3U8DownloaderKit_C_h

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
 */
typedef void (*m3u8dl_progress_callback_t)(
    m3u8dl_instance_t instance_id,
    int32_t percentage,
    const char* status_json
);

/**
 * 日志回调函数
 */
typedef void (*m3u8dl_log_callback_t)(
    m3u8dl_log_level_t level,
    const char* message
);

/**
 * 完成回调函数
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
 */
m3u8dl_instance_t m3u8dl_init(const char* config_json);

/**
 * 释放下载器实例
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
 */
void m3u8dl_set_progress_callback(m3u8dl_progress_callback_t callback);

/**
 * 设置日志回调函数
 */
void m3u8dl_set_log_callback(m3u8dl_log_callback_t callback);

/**
 * 设置完成回调函数
 */
void m3u8dl_set_completion_callback(m3u8dl_completion_callback_t callback);

/* ============================================================================
 * M3U8解析
 * ============================================================================ */

/**
 * 解析M3U8 URL（同步阻塞）
 */
char* m3u8dl_parse(m3u8dl_instance_t instance_id, const char* url);

/**
 * 异步解析M3U8 URL（非阻塞）
 */
int32_t m3u8dl_parse_async(m3u8dl_instance_t instance_id, const char* url);

/* ============================================================================
 * 下载功能
 * ============================================================================ */

/**
 * 开始下载（同步阻塞）
 */
char* m3u8dl_download(m3u8dl_instance_t instance_id, const char* request_json);

/**
 * 异步下载（非阻塞）
 */
int32_t m3u8dl_download_async(m3u8dl_instance_t instance_id, const char* request_json);

/**
 * 取消下载
 */
void m3u8dl_cancel(m3u8dl_instance_t instance_id);

/* ============================================================================
 * 功能查询
 * ============================================================================ */

/**
 * 获取可用的视频处理器列表
 */
char* m3u8dl_get_processors(m3u8dl_instance_t instance_id);

/**
 * 检查功能是否支持
 */
m3u8dl_bool_t m3u8dl_is_feature_supported(
    m3u8dl_instance_t instance_id,
    const char* feature
);

/**
 * 获取库版本信息
 */
char* m3u8dl_get_version(void);

/* ============================================================================
 * 内存管理
 * ============================================================================ */

/**
 * 释放由本库分配的字符串内存
 */
void m3u8dl_free_string(char* ptr);

/**
 * 分配内存
 */
void* m3u8dl_alloc(int32_t size);

/**
 * 释放内存
 */
void m3u8dl_free(void* ptr);

/* ============================================================================
 * 宏定义
 * ============================================================================ */

#define M3U8DL_IS_VALID_INSTANCE(id) ((id) > 0)
#define M3U8DL_SUCCEEDED(result) ((result) >= 0)
#define M3U8DL_FAILED(result) ((result) < 0)

#ifdef __cplusplus
}
#endif

#endif /* M3U8DownloaderKit_C_h */
