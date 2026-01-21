import '../domain/pattern_generation_strategy.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'hybrid/permutation_stage.dart';
import 'hybrid/diffusion_stage.dart';
import 'hybrid/substitution_stage.dart';

/// Hybrid Chaotic Pattern Generation Strategy
///
/// Multi-stage spatial pattern generation combining three chaotic algorithms:
/// Stage 1: Permutation - Arnold's Cat Map (spatial scrambling)
/// Stage 2: Diffusion - Logistic Map XOR (value mixing)
/// Stage 3: Substitution - Modular multiplication (bijective transformation)
///
/// Mathematical Properties:
/// - Deterministic: Same batch code always produces same pattern
/// - Spatially chaotic: Creates visually complex, unpredictable-looking patterns
/// - Bijective components: All stages are mathematically reversible
/// - Good distribution: Spreads ink types evenly across grid
///
/// Purpose: Manufacturing control (NOT encryption)
/// - Generates spatial deposition maps for inkjet printing
/// - Maps batch codes to unique material patterns
/// - Visual complexity prevents human-perceivable patterns
/// - Deterministic output ensures reproducible manufacturing
///
/// Note: While these algorithms ARE used in cryptography (historical context),
/// here they serve a non-cryptographic purpose: pattern generation for
/// physical anti-counterfeiting tags. Security comes from material properties,
/// not from hiding information.
class HybridChaoticPattern implements PatternGenerationStrategy {
  final PermutationStage _permutation = PermutationStage();
  final DiffusionStage _diffusion = DiffusionStage();
  final SubstitutionStage _substitution = SubstitutionStage();

  @override
  String get name => "Hybrid Chaotic Pattern (Spatial Deposition Map)";

  @override
  List<int> generatePattern(String input, int length, [int numInks = 3]) {
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

    // === DERIVE PATTERN GENERATION PARAMETERS ===
    final seed = _hashToSeed(input);
    final permIterations = _derivePermutationIterations(seed, gridSize);
    final diffSeed = _deriveDiffusionSeed(seed);
    final subMultiplier = _deriveSubstitutionMultiplier(seed, gridSize, numInks);

    // === INITIALIZE GRID ===
    var grid = _initializeGrid(input, seed, numInks, gridSize);

    // === STAGE 1: PERMUTATION ===
    grid = _permutation.permute(grid, permIterations);

    // === STAGE 2: DIFFUSION ===
    var flat = _flattenGrid(grid);
    flat = _diffusion.diffuseWithBigSeed(flat, diffSeed);

    // === STAGE 3: SUBSTITUTION ===
    flat = _substitution.substitute(flat, subMultiplier);

    // Map to final ink ID range
    return flat.map((v) => v % numInks).toList();
  }

  /// Test helper: Generate pattern without validation
  /// Exposed for testing reproducibility
  @visibleForTesting
  List<int> testGenerate(String input, int length, [int numInks = 3]) {
    return generatePattern(input, length, numInks);
  }

  /// Hash input string to BigInt seed using SHA-256
  BigInt _hashToSeed(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return BigInt.parse('0x${digest.toString()}');
  }

  /// Derive permutation iteration count from seed
  /// Use 5-44 iterations to avoid hitting the period (48)
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
}
