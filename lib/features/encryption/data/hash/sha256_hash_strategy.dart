import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../domain/encryption_strategy.dart';

/// SHA-256 Hash Strategy for generating deterministic patterns
/// NOTE: SHA-256 is a cryptographic HASH function, not encryption
/// This generates deterministic patterns from input text using hash values
/// Enhanced with optimized crypto operations
class SHA256HashStrategy implements EncryptionStrategy {
  @override
  String get name => 'SHA-256 Hash (Optimized)';

  @override
  List<int> encrypt(String input, int length) {
    if (input.isEmpty) return List.filled(length, 4);

    // Generate SHA-256 hash using optimized approach
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);

    // Convert hash to list of integers 0-4
    List<int> pattern = [];
    for (int i = 0; i < digest.bytes.length; i += 4) {
      // Combine 4 bytes to create a more uniform distribution
      int combined = 0;
      for (int j = 0; j < 4 && i + j < digest.bytes.length; j++) {
        combined = (combined << 8) | digest.bytes[i + j];
      }

      // Map to 0-4 range
      int value = combined % 5;
      pattern.add(value);
    }

    // Extend or truncate to required length
    while (pattern.length < length) {
      // Use a simple deterministic method to extend the pattern
      int lastValue = pattern[pattern.length - 1];
      int newValue = (lastValue + pattern[pattern.length % pattern.length]) % 5;
      pattern.add(newValue);
    }

    return pattern.take(length).toList();
  }

  @override
  String decrypt(List<int> encryptedData, String key) {
    // SHA-256 is a one-way hash function, not encryption
    // For LatticeLock, this generates a deterministic pattern from encrypted data
    // In production, actual decryption would happen on the backend with proper keys

    if (encryptedData.isEmpty) return "";

    // Re-hash the input key to generate deterministic output
    final keyBytes = utf8.encode(key);
    final digest = sha256.convert(keyBytes);

    // Convert hash to readable string for pattern identification
    final hexString = digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return hexString.substring(0, hexString.length > 16 ? 16 : hexString.length);
  }
}