/// Pattern Generation Strategy Interface
///
/// Defines the contract for generating spatial deposition patterns from batch codes.
/// These patterns map to physical material deposition locations for inkjet printing
/// of perovskite quantum dot anti-counterfeiting tags.
///
/// Purpose: Manufacturing control (NOT encryption or confidentiality)
/// - Maps batch codes to deterministic spatial patterns
/// - Patterns serve as deposition maps for inkjet printing
/// - Physical material properties provide anti-counterfeiting security
/// - Reversibility is NOT required (unlike encryption)
///
/// Mathematical properties:
/// - Deterministic: Same batch code always produces same pattern
/// - Bijective: Each batch code maps to unique pattern (good distribution)
/// - Spatially chaotic: Uses chaotic maps for visual complexity
abstract class PatternGenerationStrategy {
  /// Human-readable name of this pattern generation algorithm
  String get name;

  /// Generate a spatial deposition pattern from batch code
  ///
  /// Parameters:
  /// - [input]: Batch code or serial number as pattern seed
  /// - [length]: Total grid cells (e.g., 64 for 8×8 grid)
  /// - [numInks]: Number of available material inks (default: 3)
  ///
  /// Returns:
  /// - List of ink IDs (0 to numInks-1) representing deposition map
  ///
  /// Example:
  /// ```dart
  /// final strategy = HybridChaoticPattern();
  /// final pattern = strategy.generatePattern("ABC123", 64, 3);
  /// // Returns: [2, 0, 1, 2, 0, 1, 2, 0, ...] (64 values, each 0-2)
  /// ```
  ///
  /// Notes:
  /// - Output is deterministic (same input = same output)
  /// - Output values are ink IDs for material deposition
  /// - No decryption needed - batch code is embedded in metadata
  /// - Pattern serves as manufacturing blueprint, not secret data
  List<int> generatePattern(String input, int length, [int numInks = 3]);
}
