using System.Text.Json.Serialization;
using N_m3u8DL_RE.Core.API;
using N_m3u8DL_RE.Core.Abstraction;

namespace N_m3u8DL_RE.Core.Interop;

/// <summary>
/// JSON序列化上下文 - 用于NativeAOT支持
/// 使用Source Generator避免反射
/// </summary>
[JsonSourceGenerationOptions(
    WriteIndented = false,
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull)]
[JsonSerializable(typeof(DownloaderConfiguration))]
[JsonSerializable(typeof(DownloadRequest))]
[JsonSerializable(typeof(DownloadResult))]
[JsonSerializable(typeof(ParseResult))]
[JsonSerializable(typeof(StreamInfo))]
[JsonSerializable(typeof(DownloadProgress))]
[JsonSerializable(typeof(ProcessorInfo))]
[JsonSerializable(typeof(VersionInfo))]
[JsonSerializable(typeof(ErrorResult))]
[JsonSerializable(typeof(List<StreamInfo>))]
[JsonSerializable(typeof(List<ProcessorInfo>))]
[JsonSerializable(typeof(Dictionary<string, string>))]
public partial class NativeJsonContext : JsonSerializerContext
{
}
