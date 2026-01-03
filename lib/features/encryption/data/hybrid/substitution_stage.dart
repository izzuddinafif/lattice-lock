/// Substitution Stage using Modular Multiplication
///
/// Stage 3 of Hybrid Chaotic Encryption
/// Applies bijective value transformation through modular arithmetic
/// Reversible: modular inverse exists when multiplier is coprime to modulus
class SubstitutionStage {
  static const int modulus = 5; // Ink ID range [0, 4]
  static const List<int> validMultipliers = [2, 3, 4]; // Coprime to 5

  /// Apply modular multiplication substitution
  /// enc(x) = (x × m) mod p, where m is coprime to p
  List<int> substitute(List<int> data, int multiplier) {
    if (!validMultipliers.contains(multiplier)) {
      throw ArgumentError(
        'Multiplier must be coprime to 5. Valid values: $validMultipliers',
      );
    }

    return data.map((value) => (value * multiplier) % modulus).toList();
  }

  /// Inverse substitution using modular inverse
  /// dec(x) = (x × m^(-1)) mod p
  List<int> invert(List<int> data, int multiplier) {
    if (!validMultipliers.contains(multiplier)) {
      throw ArgumentError(
        'Multiplier must be coprime to 5. Valid values: $validMultipliers',
      );
    }

    int inverse = _modularInverse(multiplier, modulus);

    return data.map((value) => (value * inverse) % modulus).toList();
  }

  /// Calculate modular inverse using extended Euclidean algorithm
  /// m × m^(-1) ≡ 1 (mod p)
  ///
  /// For p=5, we precompute inverses:
  /// 2^(-1) ≡ 3 (mod 5) because 2×3 = 6 ≡ 1 (mod 5)
  /// 3^(-1) ≡ 2 (mod 5) because 3×2 = 6 ≡ 1 (mod 5)
  /// 4^(-1) ≡ 4 (mod 5) because 4×4 = 16 ≡ 1 (mod 5)
  int _modularInverse(int m, int p) {
    switch (m) {
      case 2:
        return 3;
      case 3:
        return 2;
      case 4:
        return 4;
      default:
        throw ArgumentError('Invalid multiplier: $m (must be 2, 3, or 4)');
    }
  }

  /// Derive multiplier from seed (BigInt version)
  int deriveMultiplier(BigInt seed) {
    int index = (seed % BigInt.from(validMultipliers.length)).toInt();
    return validMultipliers[index];
  }
}
