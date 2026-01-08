using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.Json;
using N_m3u8DL_RE.Core.API;
using N_m3u8DL_RE.Core.Abstraction;

namespace N_m3u8DL_RE.Core.Interop;

/// <summary>
/// N_m3u8DL-RE iOS原生导出接口
/// 使用 [UnmanagedCallersOnly] 特性导出C风格的函数
/// </summary>
public static unsafe partial class NativeExports
{
    // 全局下载器实例管理
    private static readonly Dictionary<int, M3U8DownloaderAPI> _downloaderInstances = new();
    private static readonly Dictionary<int, CancellationTokenSource> _cancellationTokens = new();
    private static readonly object _lock = new();
    private static int _nextInstanceId = 1;

    // 全局回调函数指针
    private static delegate* unmanaged[Cdecl]<int, int, IntPtr, void> _progressCallback;
    private static delegate* unmanaged[Cdecl]<int, IntPtr, void> _logCallback;
    private static delegate* unmanaged[Cdecl]<int, int, IntPtr, void> _completionCallback;

    #region 初始化与释放

    /// <summary>
    /// 初始化下载器实例
    /// </summary>
    /// <param name="configJson">JSON格式的配置字符串（UTF-8编码）</param>
    /// <returns>实例ID，失败返回-1</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_init", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static int Initialize(IntPtr configJson)
    {
        try
        {
            var config = ParseConfiguration(configJson);
            var logger = new NativeLogger(_logCallback);
            var downloader = new M3U8DownloaderAPI(logger);
            
            // 同步初始化（避免async问题）
            downloader.InitializeAsync(config).GetAwaiter().GetResult();

            lock (_lock)
            {
                var instanceId = _nextInstanceId++;
                _downloaderInstances[instanceId] = downloader;
                _cancellationTokens[instanceId] = new CancellationTokenSource();
                return instanceId;
            }
        }
        catch (Exception ex)
        {
            LogError($"Init failed: {ex.Message}");
            return -1;
        }
    }

    /// <summary>
    /// 释放下载器实例
    /// </summary>
    /// <param name="instanceId">实例ID</param>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_dispose", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static void Dispose(int instanceId)
    {
        try
        {
            lock (_lock)
            {
                if (_cancellationTokens.TryGetValue(instanceId, out var cts))
                {
                    cts.Cancel();
                    cts.Dispose();
                    _cancellationTokens.Remove(instanceId);
                }

                _downloaderInstances.Remove(instanceId);
            }
        }
        catch
        {
            // 忽略释放时的错误
        }
    }

    /// <summary>
    /// 释放所有实例
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_dispose_all", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static void DisposeAll()
    {
        try
        {
            lock (_lock)
            {
                foreach (var cts in _cancellationTokens.Values)
                {
                    cts.Cancel();
                    cts.Dispose();
                }
                _cancellationTokens.Clear();
                _downloaderInstances.Clear();
            }
        }
        catch
        {
            // 忽略释放时的错误
        }
    }

    #endregion

    #region 回调设置

    /// <summary>
    /// 设置进度回调函数
    /// </summary>
    /// <param name="callback">回调函数指针：void(int instanceId, int percentage, const char* statusJson)</param>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_set_progress_callback", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static void SetProgressCallback(delegate* unmanaged[Cdecl]<int, int, IntPtr, void> callback)
    {
        _progressCallback = callback;
    }

    /// <summary>
    /// 设置日志回调函数
    /// </summary>
    /// <param name="callback">回调函数指针：void(int level, const char* message)</param>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_set_log_callback", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static void SetLogCallback(delegate* unmanaged[Cdecl]<int, IntPtr, void> callback)
    {
        _logCallback = callback;
    }

    /// <summary>
    /// 设置完成回调函数
    /// </summary>
    /// <param name="callback">回调函数指针：void(int instanceId, int success, const char* resultJson)</param>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_set_completion_callback", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static void SetCompletionCallback(delegate* unmanaged[Cdecl]<int, int, IntPtr, void> callback)
    {
        _completionCallback = callback;
    }

    #endregion

    #region M3U8解析

    /// <summary>
    /// 解析M3U8 URL，获取流信息
    /// </summary>
    /// <param name="instanceId">实例ID</param>
    /// <param name="url">M3U8 URL（UTF-8编码）</param>
    /// <returns>JSON格式的流信息列表，需要调用 m3u8dl_free_string 释放</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_parse", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static IntPtr Parse(int instanceId, IntPtr url)
    {
        try
        {
            if (!_downloaderInstances.TryGetValue(instanceId, out var downloader))
            {
                return AllocateString(CreateErrorJson("Invalid instance ID"));
            }

            var urlString = PtrToStringUtf8(url);
            if (string.IsNullOrEmpty(urlString))
            {
                return AllocateString(CreateErrorJson("URL is null or empty"));
            }

            var cts = _cancellationTokens.GetValueOrDefault(instanceId);
            var result = downloader.ParseAsync(urlString, cts?.Token ?? CancellationToken.None)
                .GetAwaiter().GetResult();

            return AllocateString(JsonSerializer.Serialize(result, NativeJsonContext.Default.ParseResult));
        }
        catch (Exception ex)
        {
            return AllocateString(CreateErrorJson($"Parse failed: {ex.Message}"));
        }
    }

    /// <summary>
    /// 异步解析M3U8 URL（非阻塞）
    /// </summary>
    /// <param name="instanceId">实例ID</param>
    /// <param name="url">M3U8 URL（UTF-8编码）</param>
    /// <returns>0表示成功启动，-1表示失败</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_parse_async", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static int ParseAsync(int instanceId, IntPtr url)
    {
        try
        {
            if (!_downloaderInstances.TryGetValue(instanceId, out var downloader))
            {
                return -1;
            }

            var urlString = PtrToStringUtf8(url);
            if (string.IsNullOrEmpty(urlString))
            {
                return -1;
            }

            var cts = _cancellationTokens.GetValueOrDefault(instanceId);
            
            // 使用非unsafe辅助类执行async操作
            AsyncHelper.RunParseAsync(instanceId, downloader, urlString, cts?.Token ?? CancellationToken.None,
                InvokeCompletionCallback, CreateErrorJson);

            return 0;
        }
        catch
        {
            return -1;
        }
    }

    #endregion

    #region 下载功能

    /// <summary>
    /// 开始下载
    /// </summary>
    /// <param name="instanceId">实例ID</param>
    /// <param name="requestJson">JSON格式的下载请求</param>
    /// <returns>JSON格式的下载结果，需要调用 m3u8dl_free_string 释放</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_download", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static IntPtr Download(int instanceId, IntPtr requestJson)
    {
        try
        {
            if (!_downloaderInstances.TryGetValue(instanceId, out var downloader))
            {
                return AllocateString(CreateErrorJson("Invalid instance ID"));
            }

            var json = PtrToStringUtf8(requestJson);
            if (string.IsNullOrEmpty(json))
            {
                return AllocateString(CreateErrorJson("Request JSON is null or empty"));
            }

            var request = JsonSerializer.Deserialize(json, NativeJsonContext.Default.DownloadRequest);
            if (request == null)
            {
                return AllocateString(CreateErrorJson("Failed to parse request JSON"));
            }

            var cts = _cancellationTokens.GetValueOrDefault(instanceId);
            var progressCallback = new NativeProgressCallback(instanceId, _progressCallback);

            var result = downloader.DownloadAsync(request, progressCallback, cts?.Token ?? CancellationToken.None)
                .GetAwaiter().GetResult();

            return AllocateString(JsonSerializer.Serialize(result, NativeJsonContext.Default.DownloadResult));
        }
        catch (Exception ex)
        {
            return AllocateString(CreateErrorJson($"Download failed: {ex.Message}"));
        }
    }

    /// <summary>
    /// 异步下载（非阻塞）
    /// </summary>
    /// <param name="instanceId">实例ID</param>
    /// <param name="requestJson">JSON格式的下载请求</param>
    /// <returns>0表示成功启动，-1表示失败</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_download_async", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static int DownloadAsync(int instanceId, IntPtr requestJson)
    {
        try
        {
            if (!_downloaderInstances.TryGetValue(instanceId, out var downloader))
            {
                return -1;
            }

            var json = PtrToStringUtf8(requestJson);
            if (string.IsNullOrEmpty(json))
            {
                return -1;
            }

            var request = JsonSerializer.Deserialize(json, NativeJsonContext.Default.DownloadRequest);
            if (request == null)
            {
                return -1;
            }

            var cts = _cancellationTokens.GetValueOrDefault(instanceId);
            var progressCallback = new NativeProgressCallback(instanceId, _progressCallback);

            // 使用非unsafe辅助类执行async操作
            AsyncHelper.RunDownloadAsync(instanceId, downloader, request, progressCallback, cts?.Token ?? CancellationToken.None,
                InvokeCompletionCallback, CreateErrorJson);

            return 0;
        }
        catch
        {
            return -1;
        }
    }

    /// <summary>
    /// 取消下载
    /// </summary>
    /// <param name="instanceId">实例ID</param>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_cancel", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static void Cancel(int instanceId)
    {
        try
        {
            lock (_lock)
            {
                if (_cancellationTokens.TryGetValue(instanceId, out var cts))
                {
                    cts.Cancel();
                    // 创建新的CancellationTokenSource以便后续操作
                    _cancellationTokens[instanceId] = new CancellationTokenSource();
                }
            }
        }
        catch
        {
            // 忽略取消时的错误
        }
    }

    #endregion

    #region 功能查询

    /// <summary>
    /// 获取可用的视频处理器列表
    /// </summary>
    /// <param name="instanceId">实例ID</param>
    /// <returns>JSON格式的处理器列表，需要调用 m3u8dl_free_string 释放</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_get_processors", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static IntPtr GetAvailableProcessors(int instanceId)
    {
        try
        {
            if (!_downloaderInstances.TryGetValue(instanceId, out var downloader))
            {
                return AllocateString("[]");
            }

            var factory = downloader.GetVideoProcessorFactory();
            var processors = factory.GetAllProcessors()
                .Select(p => new ProcessorInfo 
                { 
                    Name = p.Name, 
                    Priority = p.Priority 
                })
                .ToList();

            return AllocateString(JsonSerializer.Serialize(processors, NativeJsonContext.Default.ListProcessorInfo));
        }
        catch
        {
            return AllocateString("[]");
        }
    }

    /// <summary>
    /// 检查功能是否支持
    /// </summary>
    /// <param name="instanceId">实例ID</param>
    /// <param name="feature">功能名称（UTF-8编码）</param>
    /// <returns>1表示支持，0表示不支持</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_is_feature_supported", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static int IsFeatureSupported(int instanceId, IntPtr feature)
    {
        try
        {
            if (!_downloaderInstances.TryGetValue(instanceId, out var downloader))
            {
                return 0;
            }

            var featureName = PtrToStringUtf8(feature);
            if (string.IsNullOrEmpty(featureName))
            {
                return 0;
            }

            var isSupported = downloader.IsFeatureAvailableAsync(featureName)
                .GetAwaiter().GetResult();

            return isSupported ? 1 : 0;
        }
        catch
        {
            return 0;
        }
    }

    /// <summary>
    /// 获取库版本信息
    /// </summary>
    /// <returns>版本字符串，需要调用 m3u8dl_free_string 释放</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_get_version", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static IntPtr GetVersion()
    {
        try
        {
            var version = new VersionInfo
            {
                Version = "1.0.0",
                Platform = "iOS",
                Framework = "NativeAOT",
                BuildDate = DateTime.UtcNow.ToString("yyyy-MM-dd")
            };
            return AllocateString(JsonSerializer.Serialize(version, NativeJsonContext.Default.VersionInfo));
        }
        catch
        {
            return AllocateString("{\"version\":\"unknown\"}");
        }
    }

    #endregion

    #region 内存管理

    /// <summary>
    /// 释放由本库分配的字符串内存
    /// </summary>
    /// <param name="ptr">字符串指针</param>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_free_string", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static void FreeString(IntPtr ptr)
    {
        if (ptr != IntPtr.Zero)
        {
            Marshal.FreeHGlobal(ptr);
        }
    }

    /// <summary>
    /// 分配内存
    /// </summary>
    /// <param name="size">大小（字节）</param>
    /// <returns>内存指针</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_alloc", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static IntPtr Allocate(int size)
    {
        return Marshal.AllocHGlobal(size);
    }

    /// <summary>
    /// 释放内存
    /// </summary>
    /// <param name="ptr">内存指针</param>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_free", CallConvs = new[] { typeof(CallConvCdecl) })]
    public static void Free(IntPtr ptr)
    {
        if (ptr != IntPtr.Zero)
        {
            Marshal.FreeHGlobal(ptr);
        }
    }

    #endregion

    #region 私有辅助方法

    private static DownloaderConfiguration? ParseConfiguration(IntPtr configJson)
    {
        if (configJson == IntPtr.Zero)
        {
            return new DownloaderConfiguration();
        }

        var json = PtrToStringUtf8(configJson);
        if (string.IsNullOrEmpty(json))
        {
            return new DownloaderConfiguration();
        }

        try
        {
            return JsonSerializer.Deserialize(json, NativeJsonContext.Default.DownloaderConfiguration) 
                   ?? new DownloaderConfiguration();
        }
        catch
        {
            return new DownloaderConfiguration();
        }
    }

    private static string? PtrToStringUtf8(IntPtr ptr)
    {
        if (ptr == IntPtr.Zero)
        {
            return null;
        }

        // 计算字符串长度
        int length = 0;
        while (Marshal.ReadByte(ptr, length) != 0)
        {
            length++;
        }

        if (length == 0)
        {
            return string.Empty;
        }

        byte[] buffer = new byte[length];
        Marshal.Copy(ptr, buffer, 0, length);
        return Encoding.UTF8.GetString(buffer);
    }

    private static IntPtr AllocateString(string str)
    {
        if (string.IsNullOrEmpty(str))
        {
            str = "";
        }

        byte[] bytes = Encoding.UTF8.GetBytes(str);
        IntPtr ptr = Marshal.AllocHGlobal(bytes.Length + 1);
        Marshal.Copy(bytes, 0, ptr, bytes.Length);
        Marshal.WriteByte(ptr, bytes.Length, 0); // null terminator
        return ptr;
    }

    private static string CreateErrorJson(string message)
    {
        var error = new ErrorResult { Success = false, ErrorMessage = message };
        return JsonSerializer.Serialize(error, NativeJsonContext.Default.ErrorResult);
    }

    private static void InvokeCompletionCallback(int instanceId, int success, string json)
    {
        if (_completionCallback != null)
        {
            var ptr = AllocateString(json);
            try
            {
                _completionCallback(instanceId, success, ptr);
            }
            finally
            {
                Marshal.FreeHGlobal(ptr);
            }
        }
    }

    private static void LogError(string message)
    {
        if (_logCallback != null)
        {
            var ptr = AllocateString(message);
            try
            {
                _logCallback(3, ptr); // 3 = Error level
            }
            finally
            {
                Marshal.FreeHGlobal(ptr);
            }
        }
    }

    #endregion
}

/// <summary>
/// 原生日志记录器实现
/// </summary>
internal unsafe class NativeLogger : ILogger
{
    private readonly delegate* unmanaged[Cdecl]<int, IntPtr, void> _callback;

    public NativeLogger(delegate* unmanaged[Cdecl]<int, IntPtr, void> callback)
    {
        _callback = callback;
    }

    public void Log(N_m3u8DL_RE.Common.Log.LogLevel level, string message)
    {
        if (_callback == null)
        {
            return;
        }

        int nativeLevel = level switch
        {
            N_m3u8DL_RE.Common.Log.LogLevel.DEBUG => 0,
            N_m3u8DL_RE.Common.Log.LogLevel.INFO => 1,
            N_m3u8DL_RE.Common.Log.LogLevel.WARN => 2,
            N_m3u8DL_RE.Common.Log.LogLevel.ERROR => 3,
            _ => 1
        };

        byte[] bytes = Encoding.UTF8.GetBytes(message);
        IntPtr ptr = Marshal.AllocHGlobal(bytes.Length + 1);
        try
        {
            Marshal.Copy(bytes, 0, ptr, bytes.Length);
            Marshal.WriteByte(ptr, bytes.Length, 0);
            _callback(nativeLevel, ptr);
        }
        finally
        {
            Marshal.FreeHGlobal(ptr);
        }
    }
}

/// <summary>
/// 原生进度回调实现
/// </summary>
internal unsafe class NativeProgressCallback : IDownloadProgressCallback
{
    private readonly int _instanceId;
    private readonly delegate* unmanaged[Cdecl]<int, int, IntPtr, void> _callback;

    public NativeProgressCallback(int instanceId, delegate* unmanaged[Cdecl]<int, int, IntPtr, void> callback)
    {
        _instanceId = instanceId;
        _callback = callback;
    }

    public void OnProgressUpdate(DownloadProgress progress)
    {
        if (_callback == null)
        {
            return;
        }

        var json = JsonSerializer.Serialize(progress, NativeJsonContext.Default.DownloadProgress);
        byte[] bytes = Encoding.UTF8.GetBytes(json);
        IntPtr ptr = Marshal.AllocHGlobal(bytes.Length + 1);
        try
        {
            Marshal.Copy(bytes, 0, ptr, bytes.Length);
            Marshal.WriteByte(ptr, bytes.Length, 0);
            _callback(_instanceId, (int)progress.Percentage, ptr);
        }
        finally
        {
            Marshal.FreeHGlobal(ptr);
        }
    }

    public void OnDownloadStarted(int taskId, string description)
    {
        OnProgressUpdate(new DownloadProgress
        {
            TaskId = taskId,
            Description = description,
            CurrentValue = 0,
            MaxValue = 100
        });
    }

    public void OnDownloadCompleted(int taskId, bool success)
    {
        OnProgressUpdate(new DownloadProgress
        {
            TaskId = taskId,
            Description = success ? "Completed" : "Failed",
            CurrentValue = 100,
            MaxValue = 100
        });
    }

    public void OnDownloadFailed(int taskId, string errorMessage)
    {
        OnProgressUpdate(new DownloadProgress
        {
            TaskId = taskId,
            Description = "Failed",
            CurrentValue = 0,
            MaxValue = 100,
            IsFailed = true,
            ErrorMessage = errorMessage
        });
    }
}

#region JSON序列化支持类型

/// <summary>
/// 处理器信息
/// </summary>
public class ProcessorInfo
{
    public string Name { get; set; } = string.Empty;
    public int Priority { get; set; }
}

/// <summary>
/// 版本信息
/// </summary>
public class VersionInfo
{
    public string Version { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty;
    public string Framework { get; set; } = string.Empty;
    public string BuildDate { get; set; } = string.Empty;
}

/// <summary>
/// 错误结果
/// </summary>
public class ErrorResult
{
    public bool Success { get; set; }
    public string ErrorMessage { get; set; } = string.Empty;
}

#endregion

#region 异步辅助类（非unsafe上下文）

/// <summary>
/// 异步操作辅助类 - 用于在非unsafe上下文中执行async/await操作
/// 解决 CS4004: Cannot await in an unsafe context 问题
/// </summary>
internal static class AsyncHelper
{
    /// <summary>
    /// 异步执行M3U8解析
    /// </summary>
    public static void RunParseAsync(
        int instanceId,
        M3U8DownloaderAPI downloader,
        string url,
        CancellationToken cancellationToken,
        Action<int, int, string> completionCallback,
        Func<string, string> createErrorJson)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                var result = await downloader.ParseAsync(url, cancellationToken);
                var json = JsonSerializer.Serialize(result, NativeJsonContext.Default.ParseResult);
                completionCallback(instanceId, result.Success ? 1 : 0, json);
            }
            catch (Exception ex)
            {
                completionCallback(instanceId, 0, createErrorJson(ex.Message));
            }
        });
    }

    /// <summary>
    /// 异步执行下载
    /// </summary>
    public static void RunDownloadAsync(
        int instanceId,
        M3U8DownloaderAPI downloader,
        DownloadRequest request,
        IDownloadProgressCallback progressCallback,
        CancellationToken cancellationToken,
        Action<int, int, string> completionCallback,
        Func<string, string> createErrorJson)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                var result = await downloader.DownloadAsync(request, progressCallback, cancellationToken);
                var resultJson = JsonSerializer.Serialize(result, NativeJsonContext.Default.DownloadResult);
                completionCallback(instanceId, result.Success ? 1 : 0, resultJson);
            }
            catch (Exception ex)
            {
                completionCallback(instanceId, 0, createErrorJson(ex.Message));
            }
        });
    }
}

#endregion
