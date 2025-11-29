abstract class EncryptionStrategy {
  String get name;
  /// Mengubah input text menjadi list angka 0-4 (sesuai jumlah tinta)
  List<int> encrypt(String input, int length);
  
  /// Untuk keperluan decryption di backend (akan diimplementasikan di backend)
  /// Mobile hanya perlu encrypt dan generate pattern
  String decrypt(List<int> encryptedData, String key);
}