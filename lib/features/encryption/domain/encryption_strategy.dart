abstract class EncryptionStrategy {
  String get name;

  /// Mengubah input text (batch code) menjadi list angka (pattern grid)
  /// numInks: jumlah ink yang tersedia (default 5 untuk backward compatibility)
  List<int> encrypt(String input, int length, [int numInks = 5]);

  /// Mendekripsi pattern kembali ke batch code asli
  /// Memerlukan kemampuan untuk membalikkan proses encryption secara matematis
  /// Untuk sistem hybrid, ini akan melibatkan brute-force melalui format constraints
  String decrypt(List<int> encryptedData);
}