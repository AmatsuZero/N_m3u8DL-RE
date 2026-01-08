using N_m3u8DL_RE.Common.Enum;
using N_m3u8DL_RE.Common.Util;
#if !IOS
using Spectre.Console;
#endif

namespace N_m3u8DL_RE.Common.Entity;

public class StreamSpec
{
    public MediaType? MediaType { get; set; }
    public string? GroupId { get; set; }
    public string? Language { get; set; }
    public string? Name { get; set; }
    public Choise? Default { get; set; }

    // 由于用户选择 被跳过的分片总时长
    public double? SkippedDuration { get; set; }

    // MSS信息
    public MSSData? MSSData { get; set; }

    // 基本信息
    public int? Bandwidth { get; set; }
    public string? Codecs { get; set; }
    public string? Resolution { get; set; }
    public double? FrameRate { get; set; }
    public string? Channels { get; set; }
    public string? Extension { get; set; }

    // Dash
    public RoleType? Role { get; set; }

    // 补充信息-色域
    public string? VideoRange { get; set; }
    // 补充信息-特征
    public string? Characteristics { get; set; }
    // 发布时间（仅MPD需要）
    public DateTime? PublishTime { get; set; }

    // 外部轨道GroupId (后续寻找对应轨道信息)
    public string? AudioId { get; set; }
    public string? VideoId { get; set; }
    public string? SubtitleId { get; set; }

    public string? PeriodId { get; set; }

    /// <summary>
    /// URL
    /// </summary>
    public string Url { get; set; } = string.Empty;

    /// <summary>
    /// 原始URL
    /// </summary>
    public string OriginalUrl { get; set; } = string.Empty;

    public Playlist? Playlist { get; set; }

    public int SegmentsCount
    {
        get
        {
            return Playlist != null ? Playlist.MediaParts.Sum(x => x.MediaSegments.Count) : 0;
        }
    }

    /// <summary>
    /// 安全转义字符串（iOS兼容）
    /// </summary>
    private static string SafeEscape(string? value)
    {
#if IOS
        return value ?? "";
#else
        return (value ?? "").EscapeMarkup();
#endif
    }

    public string ToShortString()
    {
        var prefixStr = "";
        var returnStr = "";
        var encStr = string.Empty;

        if (MediaType == Enum.MediaType.AUDIO)
        {
#if IOS
            prefixStr = $"Aud {encStr}";
#else
            prefixStr = $"[deepskyblue3]Aud[/] {encStr}";
#endif
            var d = $"{GroupId} | {(Bandwidth != null ? (Bandwidth / 1000) + " Kbps" : "")} | {Name} | {Codecs} | {Language} | {(Channels != null ? Channels + "CH" : "")} | {Role}";
            returnStr = SafeEscape(d);
        }
        else if (MediaType == Enum.MediaType.SUBTITLES)
        {
#if IOS
            prefixStr = $"Sub {encStr}";
#else
            prefixStr = $"[deepskyblue3_1]Sub[/] {encStr}";
#endif
            var d = $"{GroupId} | {Language} | {Name} | {Codecs} | {Role}";
            returnStr = SafeEscape(d);
        }
        else
        {
#if IOS
            prefixStr = $"Vid {encStr}";
#else
            prefixStr = $"[aqua]Vid[/] {encStr}";
#endif
            var d = $"{Resolution} | {Bandwidth / 1000} Kbps | {GroupId} | {FrameRate} | {Codecs} | {VideoRange} | {Role}";
            returnStr = SafeEscape(d);
        }

        returnStr = prefixStr + returnStr.Trim().Trim('|').Trim();
        while (returnStr.Contains("|  |"))
        {
            returnStr = returnStr.Replace("|  |", "|");
        }

        return returnStr.TrimEnd().TrimEnd('|').TrimEnd();
    }

    public string ToShortShortString()
    {
        var prefixStr = "";
        var returnStr = "";
        var encStr = string.Empty;

        if (MediaType == Enum.MediaType.AUDIO)
        {
#if IOS
            prefixStr = $"Aud {encStr}";
#else
            prefixStr = $"[deepskyblue3]Aud[/] {encStr}";
#endif
            var d = $"{(Bandwidth != null ? (Bandwidth / 1000) + " Kbps" : "")} | {Name} | {Language} | {(Channels != null ? Channels + "CH" : "")} | {Role}";
            returnStr = SafeEscape(d);
        }
        else if (MediaType == Enum.MediaType.SUBTITLES)
        {
#if IOS
            prefixStr = $"Sub {encStr}";
#else
            prefixStr = $"[deepskyblue3_1]Sub[/] {encStr}";
#endif
            var d = $"{Language} | {Name} | {Codecs} | {Role}";
            returnStr = SafeEscape(d);
        }
        else
        {
#if IOS
            prefixStr = $"Vid {encStr}";
#else
            prefixStr = $"[aqua]Vid[/] {encStr}";
#endif
            var d = $"{Resolution} | {Bandwidth / 1000} Kbps | {FrameRate} | {VideoRange} | {Role}";
            returnStr = SafeEscape(d);
        }

        returnStr = prefixStr + returnStr.Trim().Trim('|').Trim();
        while (returnStr.Contains("|  |"))
        {
            returnStr = returnStr.Replace("|  |", "|");
        }

        return returnStr.TrimEnd().TrimEnd('|').TrimEnd();
    }

    public override string ToString()
    {
        var prefixStr = "";
        var returnStr = "";
        var encStr = string.Empty;
        var segmentsCountStr = SegmentsCount == 0 ? "" : (SegmentsCount > 1 ? $"{SegmentsCount} Segments" : $"{SegmentsCount} Segment");

        // 增加加密标志
        if (Playlist != null && Playlist.MediaParts.Any(m => m.MediaSegments.Any(s => s.EncryptInfo.Method != EncryptMethod.NONE)))
        {
            var ms = Playlist.MediaParts.SelectMany(m => m.MediaSegments.Select(s => s.EncryptInfo.Method)).Where(e => e != EncryptMethod.NONE).Distinct();
#if IOS
            encStr = $"*{string.Join(",", ms)} ";
#else
            encStr = $"[red]*{string.Join(",", ms).EscapeMarkup()}[/] ";
#endif
        }

        if (MediaType == Enum.MediaType.AUDIO)
        {
#if IOS
            prefixStr = $"Aud {encStr}";
#else
            prefixStr = $"[deepskyblue3]Aud[/] {encStr}";
#endif
            var d = $"{GroupId} | {(Bandwidth != null ? (Bandwidth / 1000) + " Kbps" : "")} | {Name} | {Codecs} | {Language} | {(Channels != null ? Channels + "CH" : "")} | {segmentsCountStr} | {Role}";
            returnStr = SafeEscape(d);
        }
        else if (MediaType == Enum.MediaType.SUBTITLES)
        {
#if IOS
            prefixStr = $"Sub {encStr}";
#else
            prefixStr = $"[deepskyblue3_1]Sub[/] {encStr}";
#endif
            var d = $"{GroupId} | {Language} | {Name} | {Codecs} | {Characteristics} | {segmentsCountStr} | {Role}";
            returnStr = SafeEscape(d);
        }
        else
        {
#if IOS
            prefixStr = $"Vid {encStr}";
#else
            prefixStr = $"[aqua]Vid[/] {encStr}";
#endif
            var d = $"{Resolution} | {Bandwidth / 1000} Kbps | {GroupId} | {FrameRate} | {Codecs} | {VideoRange} | {segmentsCountStr} | {Role}";
            returnStr = SafeEscape(d);
        }

        returnStr = prefixStr + returnStr.Trim().Trim('|').Trim();
        while (returnStr.Contains("|  |"))
        {
            returnStr = returnStr.Replace("|  |", "|");
        }

        // 计算时长
        if (Playlist != null)
        {
            var total = Playlist.TotalDuration;
            returnStr += " | ~" + GlobalUtil.FormatTime((int)total);
        }

        return returnStr.TrimEnd().TrimEnd('|').TrimEnd();
    }
}