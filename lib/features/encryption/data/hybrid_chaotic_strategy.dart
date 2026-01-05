import '../domain/encryption_strategy.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'hybrid/permutation_stage.dart';
import 'hybrid/diffusion_stage.dart';
import 'hybrid/substitution_stage.dart';

/// Hybrid Chaotic Encryption Strategy
///
/// Multi-stage reversible encryption combining three chaotic algorithms:
/// Stage 1: Permutation - Arnold's Cat Map (spatial scrambling)
/// Stage 2: Diffusion - Logistic Map XOR (value obscuring)
/// Stage 3: Substitution - Modular multiplication (bijective transformation)
///
/// All stages are mathematically reversible, enabling pattern → batch code decryption
/// through constrained brute-force search (implemented separately in scanner)
class HybridChaoticStrategy implements EncryptionStrategy {
  final PermutationStage _permutation = PermutationStage();
  final DiffusionStage _diffusion = DiffusionStage();
  final SubstitutionStage _substitution = SubstitutionStage();

  @override
  String get name => "Hybrid Chaotic Map (Reversible)";

  @override
  List<int> encrypt(String input, int length, [int numInks = 5]) {
    // Handle empty input
    if (input.isEmpty) {
      int maxInkId = numInks - 1;
      return List.filled(length, maxInkId);
    }

    // Validate numInks
    if (numInks < 2) numInks = 2;
    if (numInks > 10) numInks = 10;

    // Calculate grid size from length (must be perfect square)
    final gridSize = sqrt(length).round();
    if (gridSize * gridSize != length) {
      throw ArgumentError('Length must be a perfect square (got $length, expected ${gridSize * gridSize})');
    }

    // === DERIVE CRYPTOGRAPHIC PARAMETERS ===
    final seed = _hashToSeed(input);
    final permIterations = _derivePermutationIterations(seed, gridSize);
    final diffSeed = _deriveDiffusionSeed(seed);
    final subMultiplier = _deriveSubstitutionMultiplier(seed, gridSize, numInks);

    // === INITIALIZE GRID ===
    var grid = _initializeGrid(input, seed, numInks, gridSize);

    // === STAGE 1: PERMUTION ===
    grid = _permutation.permute(grid, permIterations);

    // === STAGE 2: DIFFUSION ===
    var flat = _flattenGrid(grid);
    flat = _diffusion.diffuseWithBigSeed(flat, diffSeed);

    // === STAGE 3: SUBSTITUTION ===
    flat = _substitution.substitute(flat, subMultiplier);

    // Map to final ink ID range
    return flat.map((v) => v % numInks).toList();
  }

  @override
  String decrypt(List<int> encryptedData) {
    // NOTE: This is a placeholder for development
    // Actual decryption requires brute-force through batch code formats
    // or knowing the original batch code
    //
    // For production use, implement PatternScanner component that:
    // 1. Tries valid batch code formats (e.g., NNNN, NNNNNN, LLLNNN)
    // 2. For each code, generates expected pattern using encrypt()
    // 3. Finds matching pattern
    // 4. Returns original batch code

    throw UnimplementedError(
      'Decryption requires PatternScanner component with batch code format constraints.\n'
      'For development testing with known batch code, use _decryptKnown() method.',
    );
  }

  /// Internal decryption when batch code is known
  /// Useful for testing and validation
  List<int> _decryptKnown(List<int> pattern, String originalInput) {
    final seed = _hashToSeed(originalInput);

    // Calculate grid size from pattern length
    final gridSize = sqrt(pattern.length).round();

    // Infer numInks from pattern (max value + 1)
    final numInks = pattern.reduce((a, b) => a > b ? a : b) + 1;

    final permIterations = _derivePermutationIterations(seed, gridSize);
    final diffSeed = _deriveDiffusionSeed(seed);
    final subMultiplier = _deriveSubstitutionMultiplier(seed, gridSize, numInks);

    var data = List<int>.from(pattern);

    // Reverse Stage 3: Substitution
    data = _substitution.invert(data, subMultiplier);

    // Reverse Stage 2: Diffusion
    data = _diffusion.invertWithBigSeed(data, diffSeed);

    // Reverse Stage 1: Permutation
    var grid = _reshapeToGrid(data);
    grid = _permutation.invert(grid, permIterations);
    data = _flattenGrid(grid);

    return data;
  }

  /// Test helper: Direct encryption without validation
  /// Exposed for testing round-trip encryption/decryption
  @visibleForTesting
  List<int> testEncrypt(String input, int length, [int numInks = 5]) {
    return encrypt(input, length, numInks);
  }

  /// Test helper: Direct decryption when batch code is known
  /// Exposed for testing reversibility
  @visibleForTesting
  List<int> testDecrypt(List<int> pattern, String originalInput) {
    return _decryptKnown(pattern, originalInput);
  }

  /// Hash input string to BigInt seed using SHA-256
  BigInt _hashToSeed(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return BigInt.parse('0x${digest.toString()}');
  }

  /// Derive permutation iteration count from seed
  /// Use 5-44 iterations to avoid hitting the period (48)
  /// Derive permutation iteration count from hash
  /// Dynamic based on grid size to ensure good mixing
  int _derivePermutationIterations(BigInt seed, int gridSize) {
    // More iterations for larger grids
    final baseIterations = ((seed % BigInt.from(40)) + BigInt.from(5)).toInt();
    final scaleMultiplier = (gridSize / 8).ceil().clamp(1, 4);
    return baseIterations * scaleMultiplier;
  }

  /// Derive diffusion seed from hash
  BigInt _deriveDiffusionSeed(BigInt seed) {
    return seed ^ BigInt.from(0x5DEECE66); // XOR with constant for variation
  }

  /// Derive substitution multiplier from seed
  /// Pass gridSize and numInks for documentation purposes (not used in current implementation)
  int _deriveSubstitutionMultiplier(BigInt seed, int gridSize, int numInks) {
    return _substitution.deriveMultiplier(seed);
  }

  /// Initialize grid from input string and seed
  /// Dynamic grid size based on length parameter
  List<List<int>> _initializeGrid(String input, BigInt seed, int numInks, int gridSize) {
    final grid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, 0),
    );

    final bytes = utf8.encode(input);
    BigInt current = seed;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        // Use byte value with seed for deterministic initialization
        int byteIndex = (y * gridSize + x) % bytes.length;
        int byteValue = bytes[byteIndex];

        // Combine seed and byte value
        grid[y][x] = ((current + BigInt.from(byteValue)) % BigInt.from(numInks)).toInt();
        current = _lcg(current);
      }
    }

    return grid;
  }

  /// Linear Congruential Generator for deterministic randomness
  /// LCG: x(n+1) = (a × x(n) + c) mod m
  BigInt _lcg(BigInt value) {
    final a = BigInt.from(1103515245);
    final c = BigInt.from(12345);
    final m = BigInt.from(2).pow(32);

    return (value * a + c) % m;
  }

  /// Flatten 2D grid to 1D array
  List<int> _flattenGrid(List<List<int>> grid) {
    return grid.expand((row) => row).toList();
  }

  /// Reshape 1D array to 2D grid
  /// Calculate grid size from data length (must be perfect square)
  List<List<int>> _reshapeToGrid(List<int> data) {
    final size = sqrt(data.length).round();
    if (size * size != data.length) {
      throw ArgumentError(
        'Data length must be a perfect square (got $data.length)',
      );
    }

    final grid = List.generate(
      size,
      (y) => List.generate(
        size,
        (x) => data[y * size + x],
      ),
    );

    return grid;
  }
}
