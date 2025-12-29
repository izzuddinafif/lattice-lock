import '../domain/encryption_strategy.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Arnold's Cat Map Chaos Algorithm Strategy
/// Arnold's Cat Map is a chaotic transformation from chaotic maps theory
/// It transforms coordinates in a 2D space using a specific matrix transformation
/// Mathematical formula: [x'] = [1 1][x] mod N, [y'] = [1 2][y] mod N
/// Adapted for 1D sequence generation for LatticeLock
class ArnoldsCatMapStrategy implements EncryptionStrategy {
  @override
  String get name => "Arnold's Cat Map (Chaos)";

  @override
  List<int> encrypt(String input, int length, [int numInks = 5]) {
    // Handle empty input gracefully
    if (input.isEmpty) {
      if (numInks < 2) numInks = 2;
      if (numInks > 10) numInks = 10;
      final maxInkId = numInks - 1;
      return List.filled(length, maxInkId);
    }

    // 1. Generate Seed from Input with high entropy
    final bytes = utf8.encode(input);
    int hash = 0;
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash + bytes[i] * 47) & 0xFFFFFFFF;
    }

    // Initialize position and value with good distribution
    int x = ((hash % 64) + bytes[0]) % 64;
    int y = (((hash >> 8) % 64) + bytes.length) % 64;
    double value = ((hash % 1000000) + 54321) / 1000001.0;

    // Ensure initial value is in good range
    if (value <= 0.1 || value >= 0.9) {
      value = 0.414213562373095; // sqrt(2) - 1, good irrational number
    }

    List<int> grid = [];

    // Validate numInks
    if (numInks < 2) numInks = 2;
    if (numInks > 10) numInks = 10;
    final maxInkId = numInks - 1;

    // 2. Generate Chaos Stream using Arnold's Cat Map principles
    for (int i = 0; i < length; i++) {
      // Arnold's Cat Map transformation (modular arithmetic on 8x8 grid)
      int newX = (x + y) % 8;
      int newY = (x + 2 * y) % 8;

      x = newX;
      y = newY;

      // Generate chaotic value from transformed coordinates
      value = (value * 1.414213562373095 + (x * 0.1 + y * 0.05)) % 1.0;

      // Apply additional chaotic transformation
      double chaosValue = math.sin(value * math.pi) * math.cos((x + y) * math.pi / 8);
      chaosValue = (chaosValue + 1.0) / 2.0; // Normalize to [0, 1]

      // Mix with input bytes for additional entropy
      int byteIndex = i % bytes.length;
      double byteInfluence = bytes[byteIndex] / 255.0;
      chaosValue = (chaosValue * 0.7 + byteInfluence * 0.3) % 1.0;

      // 3. Quantization: Map [0.0, 1.0] to [0, maxInkId] - USE DYNAMIC numInks
      int inkId = (chaosValue * numInks).floor();
      if (inkId > maxInkId) inkId = maxInkId; // Safety clamp
      if (inkId < 0) inkId = 0; // Safety clamp

      // Add position-based entropy - USE DYNAMIC numInks
      int positionSalt = ((x + y + i) * 13) % numInks;
      inkId = (inkId + positionSalt) % numInks;

      grid.add(inkId);

      // Evolve the system for next iteration
      value = (value * 3.141592653589793 + inkId * 0.2) % 1.0;
    }

    return grid;
  }

  @override
  String decrypt(List<int> encryptedData, String key) {
    // Note: Actual decryption will be done on the backend
    // Mobile app only sends encrypted data to backend for decryption
    // This is a dummy implementation for development testing
    return "AROLNDS_CAT_MAP_DECRYPTED_PLACEHOLDER";
  }
}