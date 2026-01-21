import 'package:equatable/equatable.dart';

/// Signed pattern model combining chaotic pattern with digital signature
///
/// This model encapsulates:
/// - Chaotic pattern (visual complexity)
/// - Digital signature (authenticity proof)
/// - Metadata (batch code, timestamp, hashes)
class SignedPattern extends Equatable {
  /// Chaotic pattern array (ink IDs: 0-4)
  final List<int> pattern;

  /// Digital signature in Base64 format
  final String signature;

  /// Metadata containing batch code and verification data
  final PatternMetadata metadata;

  const SignedPattern({
    required this.pattern,
    required this.signature,
    required this.metadata,
  });

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'signature': signature,
      'metadata': metadata.toJson(),
    };
  }

  /// Create from JSON
  factory SignedPattern.fromJson(Map<String, dynamic> json) {
    return SignedPattern(
      pattern: List<int>.from(json['pattern'] as List),
      signature: json['signature'] as String,
      metadata: PatternMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [pattern, signature, metadata];
}

/// Pattern metadata for verification
class PatternMetadata extends Equatable {
  /// Original batch code (embedded for verification)
  final String batchCode;

  /// Grid size (e.g., 8 for 8×8)
  final int gridSize;

  /// Generation timestamp (ISO 8601)
  final String timestamp;

  /// Manufacturer identifier
  final String manufacturerId;

  /// SHA-256 hash of pattern for integrity check
  final String patternHash;

  /// Algorithm used for pattern generation
  final String algorithm;

  /// Number of ink types used
  final int numInks;

  const PatternMetadata({
    required this.batchCode,
    required this.gridSize,
    required this.timestamp,
    required this.manufacturerId,
    required this.patternHash,
    this.algorithm = 'Hybrid Chaotic Pattern (Spatial Deposition Map)',
    this.numInks = 3,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'batchCode': batchCode,
      'gridSize': gridSize,
      'timestamp': timestamp,
      'manufacturerId': manufacturerId,
      'patternHash': patternHash,
      'algorithm': algorithm,
      'numInks': numInks,
    };
  }

  /// Create from JSON
  factory PatternMetadata.fromJson(Map<String, dynamic> json) {
    return PatternMetadata(
      batchCode: json['batchCode'] as String,
      gridSize: json['gridSize'] as int,
      timestamp: json['timestamp'] as String,
      manufacturerId: json['manufacturerId'] as String,
      patternHash: json['patternHash'] as String,
      algorithm: json['algorithm'] as String? ?? 'Hybrid Chaotic Pattern (Spatial Deposition Map)',
      numInks: json['numInks'] as int? ?? 3,
    );
  }

  @override
  List<Object?> get props => [
        batchCode,
        gridSize,
        timestamp,
        manufacturerId,
        patternHash,
        algorithm,
        numInks,
      ];
}

/// Verification result from pattern scanner
class VerificationResult extends Equatable {
  /// Whether the pattern is authentic
  final bool isValid;

  /// Verification status details
  final VerificationStatus status;

  /// Original batch code (if valid)
  final String? batchCode;

  /// Timestamp from pattern
  final String? timestamp;

  /// Error message (if invalid)
  final String? errorMessage;

  const VerificationResult({
    required this.isValid,
    required this.status,
    this.batchCode,
    this.timestamp,
    this.errorMessage,
  });

  /// Create authentic result
  factory VerificationResult.authentic({
    required String batchCode,
    required String timestamp,
  }) {
    return VerificationResult(
      isValid: true,
      status: VerificationStatus.authentic,
      batchCode: batchCode,
      timestamp: timestamp,
    );
  }

  /// Create counterfeit result
  factory VerificationResult.counterfeit({String? reason}) {
    return VerificationResult(
      isValid: false,
      status: VerificationStatus.counterfeit,
      errorMessage: reason ?? 'Invalid digital signature',
    );
  }

  /// Create tampered result
  factory VerificationResult.tampered({String? reason}) {
    return VerificationResult(
      isValid: false,
      status: VerificationStatus.tampered,
      errorMessage: reason ?? 'Pattern does not match hash',
    );
  }

  /// Create invalid result
  factory VerificationResult.invalid({String? reason}) {
    return VerificationResult(
      isValid: false,
      status: VerificationStatus.invalid,
      errorMessage: reason ?? 'Pattern does not match batch code',
    );
  }

  @override
  List<Object?> get props => [isValid, status, batchCode, timestamp, errorMessage];
}

/// Verification status enum
enum VerificationStatus {
  /// Pattern is valid and authentic
  authentic,

  /// Invalid digital signature (counterfeit)
  counterfeit,

  /// Pattern modified after signing (tampered)
  tampered,

  /// Pattern does not match batch code (invalid)
  invalid,
}

/// Extended status enum for UI display
extension VerificationStatusExtension on VerificationStatus {
  String get displayName {
    switch (this) {
      case VerificationStatus.authentic:
        return 'Authentic';
      case VerificationStatus.counterfeit:
        return 'Counterfeit';
      case VerificationStatus.tampered:
        return 'Tampered';
      case VerificationStatus.invalid:
        return 'Invalid';
    }
  }

  String get description {
    switch (this) {
      case VerificationStatus.authentic:
        return 'This pattern is genuine and signed by the manufacturer.';
      case VerificationStatus.counterfeit:
        return 'Invalid digital signature. This may be a counterfeit product.';
      case VerificationStatus.tampered:
        return 'Pattern has been modified or corrupted.';
      case VerificationStatus.invalid:
        return 'Pattern does not match the embedded batch code.';
    }
  }
}
