using System.Security.Cryptography;

namespace N_m3u8DL_RE.Core.Crypto;

/// <summary>
/// AES加密解密工具类
/// </summary>
public static class AESUtil
{
    /// <summary>
    /// AES-128解密，解密后原地替换文件
    /// </summary>
    /// <param name="filePath">文件路径</param>
    /// <param name="keyByte">密钥字节数组</param>
    /// <param name="ivByte">初始化向量字节数组</param>
    /// <param name="mode">加密模式</param>
    /// <param name="padding">填充模式</param>
    public static void AES128Decrypt(string filePath, byte[] keyByte, byte[] ivByte, CipherMode mode = CipherMode.CBC, PaddingMode padding = PaddingMode.PKCS7)
    {
        var fileBytes = File.ReadAllBytes(filePath);
        var decrypted = AES128Decrypt(fileBytes, keyByte, ivByte, mode, padding);
        File.WriteAllBytes(filePath, decrypted);
    }

    /// <summary>
    /// AES-128解密字节数组
    /// </summary>
    /// <param name="encryptedBuff">加密的字节数组</param>
    /// <param name="keyByte">密钥字节数组</param>
    /// <param name="ivByte">初始化向量字节数组</param>
    /// <param name="mode">加密模式</param>
    /// <param name="padding">填充模式</param>
    /// <returns>解密后的字节数组</returns>
    public static byte[] AES128Decrypt(byte[] encryptedBuff, byte[] keyByte, byte[] ivByte, CipherMode mode = CipherMode.CBC, PaddingMode padding = PaddingMode.PKCS7)
    {
        byte[] inBuff = encryptedBuff;

        Aes dcpt = Aes.Create();
        dcpt.BlockSize = 128;
        dcpt.KeySize = 128;
        dcpt.Key = keyByte;
        dcpt.IV = ivByte;
        dcpt.Mode = mode;
        dcpt.Padding = padding;

        ICryptoTransform cTransform = dcpt.CreateDecryptor();
        byte[] resultArray = cTransform.TransformFinalBlock(inBuff, 0, inBuff.Length);
        return resultArray;
    }
}
