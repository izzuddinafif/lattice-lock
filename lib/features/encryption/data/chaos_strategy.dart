import '../domain/encryption_strategy.dart';
import 'dart:convert';

class ChaosLogisticStrategy implements EncryptionStrategy {
  @override
  String get name => "Logistic Map (Chaos)";

  @override
  List<int> encrypt(String input, int length) {
    // 1. Generate Seed dari Input - IMPROVED ENTROPY
    final bytes = utf8.encode(input);
    int hash = 0;
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash + bytes[i]) & 0xFFFFFFFF;
    }

    // Use multiple entropy sources for better distribution
    double x = ((hash % 1000000) + (input.length * 137)) / 1000000.0;
    if (x <= 0.01 || x >= 0.99) x = 0.123456789; // Avoid edge cases

    const double r = 3.99; // Parameter Chaos total
    List<int> grid = [];

    // 2. Generate Chaos Stream
    for (int i = 0; i < length; i++) {
      // Rumus Logistic Map: x_next = r * x * (1 - x)
      x = r * x * (1 - x);

      // 3. Quantization (Map 0.0-1.0 ke 0-4)
      int inkId = (x * 5).floor();
      if (inkId > 4) inkId = 4; // Safety clamp

      grid.add(inkId);
    }

    return grid;
  }
  
  @override
  String decrypt(List<int> encryptedData, String key) {
    // Note: Actual decryption akan dilakukan di backend
    // Mobile app hanya mengirim encrypted data ke backend untuk decryption
    // Ini dummy implementation untuk development testing
    return "DECRYPTED_DATA_PLACEHOLDER";
  }
}