import 'package:flutter/foundation.dart';
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
    print('🔥 TENT MAP encrypt() called with input="$input", length=$length');
    print('🔥 Hash computation starting...');

    // 1. Generate ultra-sensitive seed from input
    final bytes = utf8.encode(input);
    int hash = 0;
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash + bytes[i] * 31) & 0xFFFFFFFF;
      // Each character affects future characters dramatically
      hash ^= (hash << 13) + bytes[i] * (i * i + 7);
    }

    // Initialize x with extreme input sensitivity
    double x = ((hash % 999983) + (bytes.length * bytes.length * bytes.length * 211) + 12345) / 999984.0;
    if (x <= 0.001 || x >= 0.999) x = 0.618033988749895;

    if (kDebugMode) {
      print('DEBUG: input="$input" -> bytes=$bytes, hash=$hash, initial_x=$x');
    }

    const double r = 2.0; // Parameter for full chaotic behavior
    List<int> grid = [];

    // 2. Generate Chaos Stream with maximum sensitivity
    for (int i = 0; i < length; i++) {
      // MASSIVE input-sensitive perturbation at each step
      int byteInfluence = bytes[i % bytes.length] * (i + 1) * (bytes.length + 5);
      double perturbation = (byteInfluence % 137) / 1000.0; // Much larger impact

      // Modify x based on input before tent map
      x = x + perturbation;
      if (x >= 1.0) x = x - 0.999; // Wrap around with chaos

      // Tent Map formula with input modification
      if (x < 0.5) {
        x = r * x;
      } else {
        x = r * (1.0 - x);
      }

      // Ensure x stays in valid range
      if (x < 0.0) x = 0.001;
      if (x > 1.0) x = 0.999;

      // 3. Ultra-enhanced quantization with strong input coupling
      int inkId = (x * 5).floor();
      if (inkId > 4) inkId = 4;

      // EXTREME position-input coupling with overflow protection
      // Use modulo operations to prevent integer overflow
      int positionFactor = ((i % 1000) * (i % 1000) * (i % 1000) * 19) % 13;
      positionFactor ^= ((hash >> (i % 4)) & 15); // Use more hash bits
      positionFactor ^= (bytes[(i * 3) % bytes.length] % 11); // Add input byte coupling
      inkId = (inkId + positionFactor) % 5;

      // Frequent re-seeding based on input changes (every 7 steps instead of 17)
      if (i > 0 && i % 7 == 0) {
        int reseed = bytes[(i ~/ 7) % bytes.length] * (bytes.length + i) * 13;
        x = (x + (reseed % 73) / 1000.0) % 1.0;
      }

      // Add input-dependent final modification
      int finalMod = (bytes[(i + bytes.length) % bytes.length] + hash + i) % 17;
      inkId = (inkId + finalMod) % 5;

      if (kDebugMode && i < 10) { // Debug first 10 elements only
        print('DEBUG: i=$i, perturbation=$perturbation, x=$x, inkId=$inkId, positionFactor=$positionFactor, finalMod=$finalMod');
      }

      grid.add(inkId);
    }

    if (kDebugMode) {
      print('DEBUG: Final pattern for "$input": first_20=${grid.take(20).join(',')}');
      print('DEBUG: Pattern summary for "$input": length=${grid.length}, unique=${grid.toSet().length}');
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