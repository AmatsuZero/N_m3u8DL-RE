using N_m3u8DL_RE.Common.Entity;
using N_m3u8DL_RE.Common.Util;
using N_m3u8DL_RE.Core.Abstraction;
using N_m3u8DL_RE.Core.Entity;
using System.Net.Http.Headers;

namespace N_m3u8DL_RE.Core.Util;

/// <summary>
/// 下载工具类 - iOS Core版本
/// </summary>
public static class DownloadUtil
{
    private static readonly HttpClient AppHttpClient = HTTPUtil.AppHttpClient;

    /// <summary>
    /// 复制本地文件
    /// </summary>
    private static async Task<DownloadResult> CopyFileAsync(string sourceFile, string path, SpeedContainer speedContainer, long? fromPosition = null, long? toPosition = null)
    {
        using var inputStream = new FileStream(sourceFile, FileMode.Open, FileAccess.Read, FileShare.Read);
        using var outputStream = new FileStream(path, FileMode.OpenOrCreate);
        inputStream.Seek(fromPosition ?? 0L, SeekOrigin.Begin);
        var expect = (toPosition ?? inputStream.Length) - inputStream.Position + 1;
        if (expect == inputStream.Length + 1)
        {
            await inputStream.CopyToAsync(outputStream);
            speedContainer.Add(inputStream.Length);
        }
        else
        {
            var buffer = new byte[expect];
            _ = await inputStream.ReadAsync(buffer);
            await outputStream.WriteAsync(buffer);
            speedContainer.Add(buffer.Length);
        }
        return new DownloadResult()
        {
            ActualContentLength = outputStream.Length,
            ActualFilePath = path
        };
    }

    /// <summary>
    /// 下载文件到本地
    /// </summary>
    /// <param name="url">下载URL</param>
    /// <param name="path">保存路径</param>
    /// <param name="speedContainer">速度容器</param>
    /// <param name="cancellationTokenSource">取消令牌源</param>
    /// <param name="headers">HTTP请求头</param>
    /// <param name="fromPosition">起始位置</param>
    /// <param name="toPosition">结束位置</param>
    /// <param name="logger">日志记录器</param>
    /// <returns>下载结果</returns>
    public static async Task<DownloadResult> DownloadToFileAsync(
        string url, 
        string path, 
        SpeedContainer speedContainer, 
        CancellationTokenSource cancellationTokenSource, 
        Dictionary<string, string>? headers = null, 
        long? fromPosition = null, 
        long? toPosition = null,
        ILogger? logger = null)
    {
        logger ??= NullLogger.Instance;
        logger.Debug($"Fetching: {url}");
        
        // 处理file:协议
        if (url.StartsWith("file:"))
        {
            var file = new Uri(url).LocalPath;
            return await CopyFileAsync(file, path, speedContainer, fromPosition, toPosition);
        }
        
        // 处理base64:协议
        if (url.StartsWith("base64://"))
        {
            var bytes = Convert.FromBase64String(url[9..]);
            await File.WriteAllBytesAsync(path, bytes);
            return new DownloadResult()
            {
                ActualContentLength = bytes.Length,
                ActualFilePath = path,
            };
        }
        
        // 处理hex:协议
        if (url.StartsWith("hex://"))
        {
            var bytes = HexUtil.HexToBytes(url[6..]);
            await File.WriteAllBytesAsync(path, bytes);
            return new DownloadResult()
            {
                ActualContentLength = bytes.Length,
                ActualFilePath = path,
            };
        }
        
        using var request = new HttpRequestMessage(HttpMethod.Get, new Uri(url));
        if (fromPosition != null || toPosition != null)
            request.Headers.Range = new(fromPosition, toPosition);
        if (headers != null)
        {
            foreach (var item in headers)
            {
                request.Headers.TryAddWithoutValidation(item.Key, item.Value);
            }
        }
        logger.Debug($"Request headers: {request.Headers}");
        
        try
        {
            using var response = await AppHttpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationTokenSource.Token);
            
            // 处理重定向
            if (((int)response.StatusCode).ToString().StartsWith("30"))
            {
                HttpResponseHeaders respHeaders = response.Headers;
                logger.Debug($"Response headers: {respHeaders}");
                if (respHeaders.Location != null)
                {
                    var redirectedUrl = "";
                    if (!respHeaders.Location.IsAbsoluteUri)
                    {
                        Uri uri1 = new Uri(url);
                        Uri uri2 = new Uri(uri1, respHeaders.Location);
                        redirectedUrl = uri2.ToString();
                    }
                    else
                    {
                        redirectedUrl = respHeaders.Location.AbsoluteUri;
                    }
                    return await DownloadToFileAsync(redirectedUrl, path, speedContainer, cancellationTokenSource, headers, fromPosition, toPosition, logger);
                }
            }
            
            response.EnsureSuccessStatusCode();
            var contentLength = response.Content.Headers.ContentLength;
            if (speedContainer.SingleSegment) speedContainer.ResponseLength = contentLength;

            using var stream = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None);
            using var responseStream = await response.Content.ReadAsStreamAsync(cancellationTokenSource.Token);
            var buffer = new byte[16 * 1024];
            var size = 0;

            size = await responseStream.ReadAsync(buffer, cancellationTokenSource.Token);
            speedContainer.Add(size);
            await stream.WriteAsync(buffer.AsMemory(0, size));
            
            // 检测imageHeader
            bool imageHeader = ImageHeaderUtil.IsImageHeader(buffer);
            // 检测GZip（For DDP Audio）
            bool gZipHeader = buffer.Length > 2 && buffer[0] == 0x1f && buffer[1] == 0x8b;

            while ((size = await responseStream.ReadAsync(buffer, cancellationTokenSource.Token)) > 0)
            {
                speedContainer.Add(size);
                await stream.WriteAsync(buffer.AsMemory(0, size));
                // 限速策略
                while (speedContainer.Downloaded > speedContainer.SpeedLimit)
                {
                    await Task.Delay(1);
                }
            }

            return new DownloadResult()
            {
                ActualContentLength = stream.Length,
                RespContentLength = contentLength,
                ActualFilePath = path,
                ImageHeader = imageHeader,
                GzipHeader = gZipHeader
            };
        }
        catch (OperationCanceledException oce) when (oce.CancellationToken == cancellationTokenSource.Token)
        {
            speedContainer.ResetLowSpeedCount();
            throw new Exception("Download speed too slow!");
        }
    }
}
