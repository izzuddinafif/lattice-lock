import '../domain/encryption_strategy.dart';
import 'dart:convert';
import 'dart:math' as math;

class ChaosLogisticStrategy implements EncryptionStrategy {
  @override
  String get name => "Logistic Map (Enhanced Chaos)";

  @override
  List<int> encrypt(String input, int length, [int numInks = 5]) {
    // Handle empty input gracefully
    if (input.isEmpty) {
      if (numInks < 2) numInks = 2;
      if (numInks > 10) numInks = 10;
      final maxInkId = numInks - 1;
      return List.filled(length, maxInkId);
    }

    // 1. Generate MAXIMUM entropy seed from input
    final bytes = utf8.encode(input);
    double x = 0.6123456789; // Golden ratio conjugate

    // Multiple chaotic seed sources
    int hash = 0;
    int hash2 = 0;
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash + bytes[i] * 31) & 0xFFFFFFFF;
      hash2 = ((hash2 << 7) + hash2 + bytes[i] * (i + 1)) & 0xFFFFFFFF;
    }

    // Combine multiple entropy sources with maximum sensitivity
    x = ((hash + hash2) % 999983) / 999984.0;
    x = x + (bytes.length * bytes.length * 97) / 999984.0;
    x = x + (input.hashCode * 211) % 999984.0;

    // Add prime number chaos
    final primes = [9973, 9967, 99991, 999983, 999999];
    int primeIndex = (hash % primes.length);
    x = x * primes[primeIndex] / 100000.0;
    x = x % 1.0;
    if (x < 0.001) x = 0.001;
    if (x > 0.999) x = 0.999;

    const double r = 3.999999999; // Parameter near chaos threshold
    List<int> grid = [];

    // Validate numInks
    if (numInks < 2) numInks = 2; // Minimum 2 inks
    if (numInks > 10) numInks = 10; // Maximum 10 inks
    final maxInkId = numInks - 1;

    // 2. Generate TRULY chaotic stream with maximum sensitivity
    for (int i = 0; i < length; i++) {
      // Input-sensitive perturbation at EACH step
      int byteInfluence = bytes[i % bytes.length] * (i + 1) * (bytes.length + 13);
      double perturbation = (byteInfluence % 239) / 10000.0; // Bigger impact

      // Modify x before logistic map
      x = x + perturbation;
      if (x >= 1.0) x = x - 0.999;

      // Multiple logistic map operations for increased chaos
      for (int j = 0; j < 3; j++) {
        x = r * x * (1.0 - x);

        // Add position-based chaos
        x = x + (math.sin(i * 0.7 + j) * 0.1);
        x = x + (math.cos(i * 1.3 + j * 0.5) * 0.05);

        // Keep x in valid range
        if (x < 0.0) x = 0.001;
        if (x > 1.0) x = 0.999;
      }

      // EXTREME input coupling for quantization - USE DYNAMIC numInks
      int inkId = (x * numInks).floor();
      if (inkId > maxInkId) inkId = maxInkId;

      // Add chaotic position factors
      int positionFactor1 = ((i * i * 7) + (bytes[i % bytes.length] * (i + 3))) % 13;
      int positionFactor2 = ((i * i * i * 13) + (hash >> (i % 8)) + bytes[(i * 2) % bytes.length]) % 17;
      positionFactor2 ^= (hash2 >> (i % 4)) & 15;

      inkId = (inkId + positionFactor1 + positionFactor2) % numInks;

      // Re-seed frequently
      if (i > 0 && i % 13 == 0) {
        int reseed = bytes[(i ~/ 13) % bytes.length] * (bytes.length + i + 7) * 17;
        x = (x + (reseed % 137) / 1000.0) % 1.0;
      }

      // Add final input modification
      int finalMod = (bytes[(i + bytes.length) % bytes.length] + hash + hash2 + i) % 23;
      inkId = (inkId + finalMod) % numInks;

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