using System.Runtime.InteropServices;
using System.Text.Json;
using System.Text.Json.Serialization;
using N_m3u8DL_RE.iOS.Config;
using N_m3u8DL_RE.iOS.Downloader;
using N_m3u8DL_RE.iOS.Entity;

namespace N_m3u8DL_RE.iOS.PublicAPI;

/// <summary>
/// JSON 源生成器上下文（用于 AOT 支持）
/// </summary>
[JsonSourceGenerationOptions(WriteIndented = false)]
[JsonSerializable(typeof(iOSDownloaderConfig))]
internal partial class iOSJsonContext : JsonSerializerContext
{
}

/// <summary>
/// iOS Native API
/// 供 iOS/macOS 应用调用的 C 风格接口
/// </summary>
public static class iOSNativeAPI
{
    private static iOSDownloader? _downloader;
    private static DownloadProgress _lastProgress = new();
    private static unsafe delegate* unmanaged[Cdecl]<int, long, long, long, void> _progressCallback;

    /// <summary>
    /// 初始化库
    /// </summary>
    /// <returns>0=成功, 负数=错误码</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_init")]
    public static int Init()
    {
        try
        {
            Console.WriteLine("[iOS Library] Initialized");
            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[iOS Library] Init failed: {ex.Message}");
            return -1;
        }
    }

    /// <summary>
    /// 设置进度回调
    /// </summary>
    /// <param name="callback">回调函数指针 (percentage, downloadedBytes, totalBytes, speed)</param>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_set_progress_callback")]
    public static unsafe void SetProgressCallback(delegate* unmanaged[Cdecl]<int, long, long, long, void> callback)
    {
        _progressCallback = callback;
        Console.WriteLine("[iOS Library] Progress callback set");
    }

    /// <summary>
    /// 开始下载（异步）
    /// </summary>
    /// <param name="configJson">JSON 格式的配置字符串</param>
    /// <returns>0=成功启动, 负数=错误码</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_download")]
    public static unsafe int Download(byte* configJson)
    {
        try
        {
            var jsonString = Marshal.PtrToStringUTF8((IntPtr)configJson);
            if (string.IsNullOrEmpty(jsonString))
            {
                Console.WriteLine("[iOS Library] Invalid config JSON");
                return -1;
            }

            var config = JsonSerializer.Deserialize(jsonString, iOSJsonContext.Default.iOSDownloaderConfig);
            if (config == null || !config.IsValid())
            {
                Console.WriteLine("[iOS Library] Invalid configuration");
                return -2;
            }

            Console.WriteLine($"[iOS Library] Starting download: {config.GetSummary()}");

            // 创建下载器
            _downloader = new iOSDownloader();

            // 启动异步下载
            _ = DownloadTask(config);

            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[iOS Library] Download failed: {ex.Message}");
            return -99;
        }
    }

    /// <summary>
    /// 内部下载任务（非 unsafe）
    /// </summary>
    private static async Task DownloadTask(iOSDownloaderConfig config)
    {
        try
        {
            var progress = new Progress<DownloadProgress>(p =>
            {
                _lastProgress = p;
                
                // 调用进度回调
                unsafe
                {
                    if (_progressCallback != null)
                    {
                        _progressCallback(p.Percentage, p.DownloadedBytes, p.TotalBytes, p.Speed);
                    }
                }
            });

            var result = await _downloader!.DownloadAsync(config, progress);
            
            if (result.Success)
            {
                Console.WriteLine($"[iOS Library] Download completed: {result.OutputPath}");
            }
            else
            {
                Console.WriteLine($"[iOS Library] Download failed: {result.ErrorMessage}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[iOS Library] Download error: {ex.Message}");
        }
    }

    /// <summary>
    /// 简化的下载接口（使用单独的参数）
    /// </summary>
    /// <param name="url">下载 URL</param>
    /// <param name="outputPath">输出路径</param>
    /// <returns>0=成功启动, 负数=错误码</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_download_simple")]
    public static unsafe int DownloadSimple(byte* url, byte* outputPath)
    {
        try
        {
            var urlString = Marshal.PtrToStringUTF8((IntPtr)url);
            var outputPathString = Marshal.PtrToStringUTF8((IntPtr)outputPath);

            if (string.IsNullOrEmpty(urlString) || string.IsNullOrEmpty(outputPathString))
            {
                return -1;
            }

            var config = new iOSDownloaderConfig
            {
                Url = urlString,
                OutputPath = outputPathString
            };

            // 创建下载器
            _downloader = new iOSDownloader();

            // 启动异步下载
            _ = DownloadTask(config);

            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[iOS Library] Download failed: {ex.Message}");
            return -99;
        }
    }

    /// <summary>
    /// 获取下载进度
    /// </summary>
    /// <returns>进度百分比 (0-100)</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_get_progress")]
    public static int GetProgress()
    {
        return _lastProgress.Percentage;
    }

    /// <summary>
    /// 获取已下载字节数
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_get_downloaded_bytes")]
    public static long GetDownloadedBytes()
    {
        return _lastProgress.DownloadedBytes;
    }

    /// <summary>
    /// 获取总字节数
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_get_total_bytes")]
    public static long GetTotalBytes()
    {
        return _lastProgress.TotalBytes;
    }

    /// <summary>
    /// 获取下载速度
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_get_speed")]
    public static long GetSpeed()
    {
        return _lastProgress.Speed;
    }

    /// <summary>
    /// 获取下载状态
    /// </summary>
    /// <returns>状态码 (0=未开始, 1=初始化, 2=下载中, 3=合并中, 4=完成, 5=取消, 6=失败)</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_get_status")]
    public static int GetStatus()
    {
        return (int)_lastProgress.Status;
    }

    /// <summary>
    /// 取消下载
    /// </summary>
    /// <returns>0=成功, 负数=错误码</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_cancel")]
    public static int Cancel()
    {
        try
        {
            _downloader?.Cancel();
            Console.WriteLine("[iOS Library] Download cancelled");
            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[iOS Library] Cancel failed: {ex.Message}");
            return -1;
        }
    }

    /// <summary>
    /// 获取版本信息
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_get_version")]
    public static unsafe byte* GetVersion()
    {
        return (byte*)Marshal.StringToHGlobalAnsi("0.5.1-ios");
    }

    /// <summary>
    /// 获取 API 版本
    /// </summary>
    /// <returns>版本号 (MAJOR << 16 | MINOR << 8 | PATCH)</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_get_api_version")]
    public static int GetApiVersion()
    {
        // API Version 1.0.0
        return (1 << 16) | (0 << 8) | 0;
    }

    /// <summary>
    /// 释放字符串内存
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_free_string")]
    public static unsafe void FreeString(byte* ptr)
    {
        if (ptr != null)
        {
            Marshal.FreeHGlobal((IntPtr)ptr);
        }
    }

    /// <summary>
    /// 测试函数
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_ios_test")]
    public static int Test()
    {
        Console.WriteLine("[iOS Library] Test function called");
        return 42;
    }
}
