using System.Runtime.InteropServices;

namespace N_m3u8DL_RE.Core.PublicAPI;

/// <summary>
/// Native API for iOS/macOS integration
/// 供外部调用的公共 API 接口
/// </summary>
public static class NativeAPI
{
    // 回调函数类型定义
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    public delegate void ProgressCallback(int progress, long downloadedBytes, long totalBytes);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    public delegate void CompletionCallback(int result, byte* outputPath);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    public delegate void ErrorCallback(int errorCode, byte* errorMessage);

    // 存储回调函数
    private static delegate* unmanaged[Cdecl]<int, long, long, void> _progressCallback;
    private static delegate* unmanaged[Cdecl]<int, byte*, void> _completionCallback;

    /// <summary>
    /// 初始化库
    /// </summary>
    /// <returns>0表示成功，负数表示错误</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_init")]
    public static int Init()
    {
        try
        {
            // 初始化日志、配置等
            Console.WriteLine("N_m3u8DL-RE Core Library initialized");
            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Init failed: {ex.Message}");
            return -1;
        }
    }

    /// <summary>
    /// 设置进度回调
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_set_progress_callback")]
    public static unsafe void SetProgressCallback(delegate* unmanaged[Cdecl]<int, long, long, void> callback)
    {
        _progressCallback = callback;
    }

    /// <summary>
    /// 开始下载
    /// </summary>
    /// <param name="urlPtr">下载URL</param>
    /// <param name="outputPathPtr">输出路径</param>
    /// <param name="completionCallback">完成回调</param>
    /// <returns>0表示成功启动，负数表示错误</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_download")]
    public static unsafe int Download(
        byte* urlPtr,
        byte* outputPathPtr,
        delegate* unmanaged[Cdecl]<int, byte*, void> completionCallback)
    {
        try
        {
            string url = Marshal.PtrToStringUTF8((IntPtr)urlPtr) ?? "";
            string outputPath = Marshal.PtrToStringUTF8((IntPtr)outputPathPtr) ?? "";
            
            if (string.IsNullOrEmpty(url))
            {
                return -2; // 无效的URL
            }

            _completionCallback = completionCallback;
            
            Console.WriteLine($"Starting download: {url} -> {outputPath}");
            
            // TODO: 实际的下载逻辑
            // Task.Run(async () => {
            //     try {
            //         await DownloadAsync(url, outputPath);
            //         if (_completionCallback != null) {
            //             var pathBytes = Marshal.StringToHGlobalAnsi(outputPath);
            //             _completionCallback(0, (byte*)pathBytes);
            //         }
            //     } catch {
            //         if (_completionCallback != null) {
            //             _completionCallback(-1, null);
            //         }
            //     }
            // });
            
            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Download failed: {ex.Message}");
            return -1;
        }
    }

    /// <summary>
    /// 获取下载进度
    /// </summary>
    /// <returns>进度百分比 (0-100)</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_get_progress")]
    public static int GetProgress()
    {
        // TODO: 返回实际的下载进度
        return 0;
    }

    /// <summary>
    /// 取消下载
    /// </summary>
    /// <returns>0表示成功，负数表示错误</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_cancel")]
    public static int Cancel()
    {
        try
        {
            // TODO: 取消下载逻辑
            Console.WriteLine("Download cancelled");
            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Cancel failed: {ex.Message}");
            return -1;
        }
    }

    /// <summary>
    /// 获取版本信息
    /// </summary>
    /// <returns>版本字符串指针</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_get_version")]
    public static unsafe byte* GetVersion()
    {
        string version = "0.5.1";
        return (byte*)Marshal.StringToHGlobalAnsi(version);
    }

    /// <summary>
    /// 释放字符串内存
    /// </summary>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_free_string")]
    public static unsafe void FreeString(byte* ptr)
    {
        if (ptr != null)
        {
            Marshal.FreeHGlobal((IntPtr)ptr);
        }
    }

    /// <summary>
    /// 获取API版本号
    /// </summary>
    /// <returns>版本号 (MAJOR << 16 | MINOR << 8 | PATCH)</returns>
    [UnmanagedCallersOnly(EntryPoint = "m3u8dl_get_api_version")]
    public static int GetApiVersion()
    {
        // API Version 1.0.0
        return (1 << 16) | (0 << 8) | 0;
    }
}
