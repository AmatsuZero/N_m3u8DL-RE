using CSChaCha20;

namespace N_m3u8DL_RE.Core.Crypto;

/// <summary>
/// ChaCha20加密解密工具类
/// </summary>
public static class ChaCha20Util
{
    /// <summary>
    /// 按每1024字节解密
    /// </summary>
    /// <param name="encryptedBuff">加密的字节数组</param>
    /// <param name="keyBytes">密钥字节数组（必须32字节）</param>
    /// <param name="nonceBytes">Nonce字节数组（必须8或12字节）</param>
    /// <returns>解密后的字节数组</returns>
    /// <exception cref="Exception">密钥或Nonce长度不正确时抛出异常</exception>
    public static byte[] DecryptPer1024Bytes(byte[] encryptedBuff, byte[] keyBytes, byte[] nonceBytes)
    {
        if (keyBytes.Length != 32)
            throw new Exception("Key must be 32 bytes!");
        if (nonceBytes.Length != 12 && nonceBytes.Length != 8)
            throw new Exception("Key must be 12 or 8 bytes!");
        if (nonceBytes.Length == 8)
            nonceBytes = (new byte[4] { 0, 0, 0, 0 }).Concat(nonceBytes).ToArray();

        var decStream = new MemoryStream();
        using BinaryReader reader = new BinaryReader(new MemoryStream(encryptedBuff));
        using (BinaryWriter writer = new BinaryWriter(decStream))
            while (true)
            {
                var buffer = reader.ReadBytes(1024);
                byte[] dec = new byte[buffer.Length];
                if (buffer.Length > 0)
                {
                    ChaCha20 forDecrypting = new ChaCha20(keyBytes, nonceBytes, 0);
                    forDecrypting.DecryptBytes(dec, buffer);
                    writer.Write(dec, 0, dec.Length);
                }
                else
                {
                    break;
                }
            }

        return decStream.ToArray();
    }
}
