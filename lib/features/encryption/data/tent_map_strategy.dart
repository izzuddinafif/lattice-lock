import '../domain/encryption_strategy.dart';
import 'dart:convert';

/// Tent Map Chaos Algorithm Strategy
/// The Tent Map is a piecewise linear chaotic map with good entropy properties
/// Mathematical formula: x_next = { r * x, if x < 0.5; r * (1 - x), if x >= 0.5 }
/// where r is typically 2.0 for full chaotic behavior
class TentMapStrategy implements EncryptionStrategy {
  @override
  String get name => "Tent Map (Chaos)";

  @override
  List<int> encrypt(String input, int length) {
    // 1. Generate Seed from Input with improved entropy
    final bytes = utf8.encode(input);
    int hash = 0;
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash + bytes[i] * 31) & 0xFFFFFFFF;
    }

    // Initialize x with good distribution and avoid edge cases
    double x = ((hash % 1000000) + (input.length * 137) + 12345) / 1000001.0;
    if (x <= 0.1 || x >= 0.9) x = 0.618033988749895; // Golden ratio conjugate

    const double r = 2.0; // Parameter for full chaotic behavior
    List<int> grid = [];

    // 2. Generate Chaos Stream using Tent Map
    for (int i = 0; i < length; i++) {
      // Tent Map formula with conditional branches
      if (x < 0.5) {
        x = r * x;
      } else {
        x = r * (1.0 - x);
      }

      // Ensure x stays in valid range [0, 1]
      if (x < 0.0) x = 0.0;
      if (x > 1.0) x = 1.0;

      // 3. Quantization: Map [0.0, 1.0] to [0, 4]
      int inkId = (x * 5).floor();
      if (inkId > 4) inkId = 4; // Safety clamp

      // Add additional entropy based on position
      int positionFactor = (i * 7 + bytes[i % bytes.length]) % 5;
      inkId = (inkId + positionFactor) % 5;

      grid.add(inkId);
    }

    return grid;
  }

  @override
  String decrypt(List<int> encryptedData, String key) {
    // Note: Actual decryption will be done on the backend
    // Mobile app only sends encrypted data to backend for decryption
    // This is a dummy implementation for development testing
    return "TENT_MAP_DECRYPTED_PLACEHOLDER";
  }
}