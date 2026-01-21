/// Diffusion Stage using Logistic Map Chaotic Sequence
///
/// Stage 2 of Hybrid Chaotic Encryption
/// Obscures values through XOR with chaotic sequence
/// Reversible: XOR is self-inverse (a⊕b⊕b = a)
class DiffusionStage {
  /// Apply XOR diffusion with logistic map generated sequence
  /// Logistic map: x(n+1) = r × x(n) × (1 - x(n))
  /// where r = 3.999999999 (chaos parameter)
  List<int> diffuse(List<int> data, int seed) {
    var sequence = _generateLogisticSequence(seed, data.length);
    var result = List<int>.from(data);

    for (int i = 0; i < data.length; i++) {
      result[i] = result[i] ^ sequence[i];
    }

    return result;
  }

  /// Inverse diffusion (XOR is self-inverse, same operation)
  List<int> invert(List<int> data, int seed) {
    return diffuse(data, seed);
  }

  /// Generate chaotic sequence using logistic map
  /// Returns sequence of values in 0-4 range (ink IDs)
  List<int> _generateLogisticSequence(int seed, int length) {
    const double r = 3.999999999; // Chaos parameter near 4.0

    // Initialize from seed (normalize to [0, 1])
    double x = (seed % 10000) / 10000.0;

    // Ensure x is in chaotic range (0, 1), excluding endpoints
    if (x <= 0.001) x = 0.001;
    if (x >= 0.999) x = 0.999;

    var sequence = List<int>.filled(length, 0);

    for (int i = 0; i < length; i++) {
      // Apply logistic map equation
      x = r * x * (1.0 - x);

      // Keep in valid range
      if (x < 0.0) x = 0.001;
      if (x > 1.0) x = 0.999;

      // Map to ink ID range [0, 4]
      sequence[i] = (x * 5).floor() % 5;
    }

    return sequence;
  }

  /// Generate chaotic sequence using BigInt seed for better entropy
  List<int> diffuseWithBigSeed(List<int> data, BigInt bigSeed) {
    var sequence = _generateLogisticSequenceBig(bigSeed, data.length);
    var result = List<int>.from(data);

    for (int i = 0; i < data.length; i++) {
      result[i] = result[i] ^ sequence[i];
    }

    return result;
  }

  /// Inverse diffusion with BigInt seed
  List<int> invertWithBigSeed(List<int> data, BigInt bigSeed) {
    return diffuseWithBigSeed(data, bigSeed);
  }

  /// Generate chaotic sequence using BigInt seed
  List<int> _generateLogisticSequenceBig(BigInt seed, int length) {
    const double r = 3.999999999;

    // Use more bits from BigInt for better distribution
    double x = (seed % BigInt.from(1000000)).toInt() / 1000000.0;

    if (x <= 0.001) x = 0.001;
    if (x >= 0.999) x = 0.999;

    var sequence = List<int>.filled(length, 0);

    for (int i = 0; i < length; i++) {
      x = r * x * (1.0 - x);

      if (x < 0.0) x = 0.001;
      if (x > 1.0) x = 0.999;

      sequence[i] = (x * 5).floor() % 5;
    }

    return sequence;
  }
}
