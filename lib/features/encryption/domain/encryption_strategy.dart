abstract class EncryptionStrategy {
  String get name;
  /// Mengubah input text menjadi list angka (sesuai jumlah tinta)
  /// numInks: jumlah ink yang tersedia (default 5 untuk backward compatibility)
  List<int> encrypt(String input, int length, [int numInks = 5]);

  /// Untuk keperluan decryption di backend (akan diimplementasikan di backend)
  /// Mobile hanya perlu encrypt dan generate pattern
  String decrypt(List<int> encryptedData, String key);
}