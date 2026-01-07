using System.IO.Compression;

namespace N_m3u8DL_RE.Core.Util;

/// <summary>
/// 其他工具类
/// </summary>
public static class OtherUtil
{
    /// <summary>
    /// 解压GZip文件并替换原文件
    /// </summary>
    /// <param name="filePath">文件路径</param>
    public static async Task DeGzipFileAsync(string filePath)
    {
        var deGzipFile = Path.ChangeExtension(filePath, ".dezip_tmp");
        try
        {
            await using (var fileToDecompressAsStream = File.OpenRead(filePath))
            {
                await using var decompressedStream = File.Create(deGzipFile);
                await using var decompressionStream = new GZipStream(fileToDecompressAsStream, CompressionMode.Decompress);
                await decompressionStream.CopyToAsync(decompressedStream);
            };
            File.Delete(filePath);
            File.Move(deGzipFile, filePath);
        }
        catch 
        {
            if (File.Exists(deGzipFile)) File.Delete(deGzipFile);
        }
    }
}
