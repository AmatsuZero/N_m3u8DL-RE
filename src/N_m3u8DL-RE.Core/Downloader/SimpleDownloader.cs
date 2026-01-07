using N_m3u8DL_RE.Common.Entity;
using N_m3u8DL_RE.Common.Enum;
using N_m3u8DL_RE.Core.Abstraction;
using N_m3u8DL_RE.Core.Config;
using N_m3u8DL_RE.Core.Crypto;
using N_m3u8DL_RE.Core.Entity;
using N_m3u8DL_RE.Core.Util;

namespace N_m3u8DL_RE.Core.Downloader;

/// <summary>
/// 简单下载器 - iOS Core版本
/// </summary>
public class SimpleDownloader : IDownloader
{
    private readonly DownloaderConfig _downloaderConfig;
    private readonly ILogger _logger;

    public SimpleDownloader(DownloaderConfig config, ILogger? logger = null)
    {
        _downloaderConfig = config;
        _logger = logger ?? NullLogger.Instance;
    }

    public async Task<DownloadResult?> DownloadSegmentAsync(
        MediaSegment segment, 
        string savePath, 
        SpeedContainer speedContainer, 
        Dictionary<string, string>? headers = null,
        CancellationToken cancellationToken = default)
    {
        var url = segment.Url;
        var (des, dResult) = await DownClipAsync(url, savePath, speedContainer, segment.StartRange, segment.StopRange, headers, 3, cancellationToken);
        
        if (dResult is { Success: true } && dResult.ActualFilePath != des)
        {
            // 解密处理
            await DecryptSegmentAsync(segment, dResult);

            // Image头处理
            if (dResult.ImageHeader)
            {
                await ImageHeaderUtil.ProcessAsync(dResult.ActualFilePath);
            }
            
            // Gzip解压
            if (dResult.GzipHeader)
            {
                await OtherUtil.DeGzipFileAsync(dResult.ActualFilePath);
            }

            // 处理完成后改名
            File.Move(dResult.ActualFilePath, des);
            dResult.ActualFilePath = des;
        }
        
        return dResult;
    }

    private async Task DecryptSegmentAsync(MediaSegment segment, DownloadResult result)
    {
        switch (segment.EncryptInfo.Method)
        {
            case EncryptMethod.AES_128:
            {
                var key = segment.EncryptInfo.Key;
                var iv = segment.EncryptInfo.IV;
                AESUtil.AES128Decrypt(result.ActualFilePath, key!, iv!);
                break;
            }
            case EncryptMethod.AES_128_ECB:
            {
                var key = segment.EncryptInfo.Key;
                var iv = segment.EncryptInfo.IV;
                AESUtil.AES128Decrypt(result.ActualFilePath, key!, iv!, System.Security.Cryptography.CipherMode.ECB);
                break;
            }
            case EncryptMethod.CHACHA20:
            {
                var key = segment.EncryptInfo.Key;
                var nonce = segment.EncryptInfo.IV;

                var fileBytes = await File.ReadAllBytesAsync(result.ActualFilePath);
                var decrypted = ChaCha20Util.DecryptPer1024Bytes(fileBytes, key!, nonce!);
                await File.WriteAllBytesAsync(result.ActualFilePath, decrypted);
                break;
            }
            case EncryptMethod.SAMPLE_AES_CTR:
                // 不支持的加密方式
                _logger.Warn($"SAMPLE-AES-CTR encryption is not supported");
                break;
        }
    }

    private async Task<(string des, DownloadResult? dResult)> DownClipAsync(
        string url, 
        string path, 
        SpeedContainer speedContainer, 
        long? fromPosition, 
        long? toPosition, 
        Dictionary<string, string>? headers = null, 
        int retryCount = 3,
        CancellationToken cancellationToken = default)
    {
        CancellationTokenSource? cancellationTokenSource = null;
        
        retry:
        try
        {
            cancellationTokenSource = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            var des = Path.ChangeExtension(path, null);

            // 已下载跳过
            if (File.Exists(des))
            {
                speedContainer.Add(new FileInfo(des).Length);
                return (des, new DownloadResult() { ActualContentLength = 0, ActualFilePath = des });
            }

            // 已解密跳过
            var dec = Path.Combine(Path.GetDirectoryName(des)!, Path.GetFileNameWithoutExtension(des) + "_dec" + Path.GetExtension(des));
            if (File.Exists(dec))
            {
                speedContainer.Add(new FileInfo(dec).Length);
                return (dec, new DownloadResult() { ActualContentLength = 0, ActualFilePath = dec });
            }

            // 另起线程进行监控
            var cts = cancellationTokenSource;
            using var watcher = Task.Factory.StartNew(async () =>
            {
                while (true)
                {
                    if (cts.IsCancellationRequested) break;
                    if (speedContainer.ShouldStop)
                    {
                        cts.Cancel();
                        _logger.Debug("Download cancelled");
                        break;
                    }
                    await Task.Delay(500, CancellationToken.None);
                }
            }, TaskCreationOptions.LongRunning);

            // 调用下载
            var result = await DownloadUtil.DownloadToFileAsync(url, path, speedContainer, cancellationTokenSource, headers, fromPosition, toPosition, _logger);
            return (des, result);
        }
        catch (Exception ex)
        {
            _logger.Debug($"{ex.Message} retryCount: {retryCount}");
            _logger.Debug($"{url} {ex}");
            
            if (retryCount-- > 0)
            {
                await Task.Delay(1000, cancellationToken);
                goto retry;
            }
            else
            {
                _logger.Error($"Download failed after retries: {ex.Message}, URL: {url}");
                _logger.Warn($"{ex.Message}");
            }
            
            return default;
        }
        finally
        {
            cancellationTokenSource?.Dispose();
        }
    }
}
