import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../pattern/domain/pattern_generation_strategy.dart';
import '../../pattern/data/hybrid_chaotic_pattern.dart';
import 'signature_service.dart';
import '../../../core/models/signed_pattern.dart';

/// Secure pattern generator combining pattern generation with digital signature
///
/// Workflow:
/// 1. Generate spatial deposition pattern from batch code (chaotic maps)
/// 2. Create metadata with batch code and pattern hash
/// 3. Sign metadata with manufacturer private key (authenticity proof)
/// 4. Return SignedPattern containing all three components
///
/// Purpose: Manufacturing control and document integrity
/// - NOT for hiding information (batch code is embedded in metadata)
/// - Digital signature protects PDF blueprints from tampering
/// - Physical security comes from material properties, not digital encryption
class SecurePatternGenerator {
  final SignatureService _signatureService;
  final PatternGenerationStrategy _patternStrategy;
  final String _manufacturerId;

  SecurePatternGenerator({
    required SignatureService signatureService,
    PatternGenerationStrategy? patternStrategy,
    String manufacturerId = 'latticelock-official',
  })  : _signatureService = signatureService,
        _patternStrategy = patternStrategy ?? HybridChaoticPattern(),
        _manufacturerId = manufacturerId;

  /// Generate signed pattern from batch code
  ///
  /// This should ONLY run on the server with access to the private key
  Future<SignedPattern> generatePattern({
    required String batchCode,
    required int gridSize,
    int numInks = 3,
  }) async {
    // Step 1: Generate spatial deposition pattern
    final pattern = _patternStrategy.generatePattern(
      batchCode,
      gridSize * gridSize,
      numInks,
    );

    // Step 2: Create metadata with batch code embedded
    final patternHash = sha256.convert(pattern).toString();

    final metadata = PatternMetadata(
      batchCode: batchCode,
      gridSize: gridSize,
      timestamp: DateTime.now().toIso8601String(),
      manufacturerId: _manufacturerId,
      patternHash: patternHash,
      algorithm: _patternStrategy.name,
      numInks: numInks,
    );

    // Step 3: Sign metadata with PRIVATE KEY (server only!)
    final metadataJson = jsonEncode(metadata.toJson());
    final signature = await _signatureService.sign(metadataJson);

    // Step 4: Return signed pattern
    return SignedPattern(
      pattern: pattern,
      signature: signature,
      metadata: metadata,
    );
  }

  /// Generate multiple signed patterns in batch
  Future<List<SignedPattern>> generateBatch({
    required List<String> batchCodes,
    required int gridSize,
    int numInks = 3,
  }) async {
    final results = <SignedPattern>[];

    for (final batchCode in batchCodes) {
      final signedPattern = await generatePattern(
        batchCode: batchCode,
        gridSize: gridSize,
        numInks: numInks,
      );
      results.add(signedPattern);
    }

    return results;
  }
}

/// Pattern verifier for client-side scanning
///
/// This runs on the client app with the PUBLIC KEY embedded
/// NO user input required - everything comes from the QR/pattern scan
class PatternVerifier {
  final SignatureService _signatureService;
  final PatternGenerationStrategy _patternStrategy;

  PatternVerifier({
    required SignatureService signatureService,
    PatternGenerationStrategy? patternStrategy,
  })  : _signatureService = signatureService,
        _patternStrategy = patternStrategy ?? HybridChaoticPattern();

  /// Verify scanned pattern
  ///
  /// Input comes from scanner:
  /// - scannedPattern: List<int> from camera/grid detection
  /// - scannedSignature: String from QR code
  /// - scannedMetadata: Map from QR code
  ///
  /// Output: VerificationResult showing authentic/counterfeit/tampered/invalid
  Future<VerificationResult> verifyPattern({
    required List<int> scannedPattern,
    required String scannedSignature,
    required Map<String, dynamic> scannedMetadata,
  }) async {
    try {
      // Parse metadata
      final metadata = PatternMetadata.fromJson(scannedMetadata);

      // === CHECK 1: Verify digital signature (authenticity) ===
      final metadataJson = jsonEncode(metadata.toJson());
      final isValidSignature = await _signatureService.verify(
        metadataJson,
        scannedSignature,
      );

      if (!isValidSignature) {
        return VerificationResult.counterfeit(
          reason: 'Invalid digital signature - not signed by manufacturer',
        );
      }

      // === CHECK 2: Verify pattern integrity (tamper detection) ===
      final expectedHash = sha256.convert(scannedPattern).toString();
      if (expectedHash != metadata.patternHash) {
        return VerificationResult.tampered(
          reason: 'Pattern has been modified or corrupted',
        );
      }

      // === CHECK 3: Verify pattern matches batch code (consistency) ===
      try {
        final expectedPattern = _patternStrategy.generatePattern(
          metadata.batchCode,
          metadata.gridSize * metadata.gridSize,
          metadata.numInks,
        );

        if (!_listEquals(scannedPattern, expectedPattern)) {
          return VerificationResult.invalid(
            reason: 'Pattern does not match the embedded batch code',
          );
        }
      } catch (e) {
        return VerificationResult.invalid(
          reason: 'Failed to regenerate pattern: $e',
        );
      }

      // === ALL CHECKS PASSED: Pattern is authentic ===
      return VerificationResult.authentic(
        batchCode: metadata.batchCode,
        timestamp: metadata.timestamp,
      );
    } catch (e) {
      return VerificationResult.invalid(
        reason: 'Verification error: $e',
      );
    }
  }

  /// Verify from SignedPattern object (convenience method)
  Future<VerificationResult> verifySignedPattern(
    SignedPattern signedPattern,
  ) async {
    return await verifyPattern(
      scannedPattern: signedPattern.pattern,
      scannedSignature: signedPattern.signature,
      scannedMetadata: signedPattern.metadata.toJson(),
    );
  }

  /// Compare two lists for equality
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
