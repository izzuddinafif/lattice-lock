import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../encryption/domain/encryption_strategy.dart';
import '../../encryption/data/hybrid_chaotic_strategy.dart';
import '../../material/models/ink_profile.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/native_crypto_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/history_service.dart';

class GeneratorUseCase {
  EncryptionStrategy _encryptionStrategy = HybridChaoticStrategy(); // Default strategy
  bool _useNativeCrypto = false; // Flag to use native crypto for sensitive operations
  String? _currentKeyId; // Current key ID for encryption

  /// Initialize the generator use case with native crypto
  Future<void> initialize() async {
    try {
      await NativeCryptoService.initialize();
      _currentKeyId = await NativeCryptoService.generateNewKey();
      _useNativeCrypto = await NativeCryptoService.isAvailable();
    } catch (e) {
      _useNativeCrypto = false;
    }
  }

  /// Generate a secure key for encryption
  Future<String> generateSecureKey({String? keyId}) async {
    try {
      return await NativeCryptoService.generateNewKey(keyId: keyId);
    } catch (e) {
      throw Exception('Failed to generate secure key: $e');
    }
  }

  /// Encrypt sensitive data using native crypto
  Future<Map<String, dynamic>> encryptSensitiveData(String data) async {
    try {
      if (_useNativeCrypto && _currentKeyId != null) {
        final encryptedWithHash = await NativeCryptoService.encryptWithHash(
          data, 
          keyId: _currentKeyId,
        );
        return {
          'encryptedData': encryptedWithHash.encryptedData.toJson(),
          'hash': encryptedWithHash.hash,
          'keyId': encryptedWithHash.encryptedData.keyId,
          'isNativeCrypto': true,
        };
      } else {
        // Fallback to hybrid chaotic strategy for backwards compatibility
        final hybridStrategy = HybridChaoticStrategy();
        final encryptedPattern = hybridStrategy.encrypt(data, data.length);
        return {
          'pattern': encryptedPattern,
          'isNativeCrypto': false,
        };
      }
    } catch (e) {
      throw Exception('Failed to encrypt sensitive data: $e');
    }
  }

  /// Decrypt sensitive data using native crypto
  Future<String> decryptSensitiveData(Map<String, dynamic> encryptedData) async {
    try {
      if (encryptedData['isNativeCrypto'] == true) {
        final encryptedDataObj = EncryptedData.fromJson(encryptedData['encryptedData']);
        final hash = base64.decode(encryptedData['hash']);
        final encryptedWithHash = EncryptedWithHash(
          encryptedData: encryptedDataObj,
          hash: hash,
        );
        return await NativeCryptoService.decryptWithHashVerification(encryptedWithHash);
      } else {
        // For backwards compatibility, return placeholder
        return "DECRYPTED_DATA_PLACEHOLDER";
      }
    } catch (e) {
      throw Exception('Failed to decrypt sensitive data: $e');
    }
  }

  /// Get performance metrics for crypto operations
  Future<Map<String, dynamic>?> getPerformanceMetrics() async {
    try {
      if (_useNativeCrypto) {
        final metrics = await NativeCryptoService.getPerformanceMetrics();
        return {
          'nativeCryptoAvailable': true,
          'encryptionTimeMs': metrics.encryptionTimeMs,
          'decryptionTimeMs': metrics.decryptionTimeMs,
          'speedImprovement': metrics.speedImprovement,
          'testDataSize': metrics.testDataSize,
          'iterations': metrics.iterations,
        };
      } else {
        return {
          'nativeCryptoAvailable': false,
          'message': 'Using fallback chaos algorithms',
        };
      }
    } catch (e) {
      return {
        'nativeCryptoAvailable': false,
        'error': e.toString(),
      };
    }
  }

  void setAlgorithm(String algorithm) {
    // All algorithms now use the Hybrid Chaotic Strategy (reversible encryption)
    // The algorithm parameter is kept for backward compatibility but doesn't change behavior
    _encryptionStrategy = HybridChaoticStrategy();
  }

  Future<List<int>> generatePattern({
    required String inputText,
    required String algorithm,
    int? gridSize, // Optional grid size parameter
    int? numInks, // Number of inks in the material profile (default to 5 for backward compatibility)
  }) async {
    // Set algorithm based on selection
    setAlgorithm(algorithm);

    // Calculate total cells based on grid size (default to 8x8 for backward compatibility)
    final totalCells = AppConstants.getTotalCells(gridSize ?? AppConstants.defaultGridSize);

    // Encrypt input text to pattern with dynamic ink count
    final encryptedData = _encryptionStrategy.encrypt(
      inputText,
      totalCells,
      numInks ?? 5, // Default to 5 inks if not specified
    );

    return encryptedData;
  }

  Future<void> generatePDF({
    required List<int> pattern,
    required MaterialProfile material,
    required String inputText,
    int? gridSize, // Optional grid size parameter
  }) async {
    try {
      final pdfService = PDFService.create();
      // Use the SAME global HistoryService instance that the history provider uses
      final historyService = globalHistoryService;

      // Use provided grid size or default to 8x8 for backward compatibility
      final actualGridSize = gridSize ?? AppConstants.defaultGridSize;

      // Convert pattern to 2D array for compatibility
      final pattern2D = <List<int>>[];
      for (int i = 0; i < pattern.length; i += actualGridSize) {
        final end = (i + actualGridSize).clamp(0, pattern.length);
        pattern2D.add(pattern.sublist(i, end));
      }

      // Extract material colors for backend PDF generation
      final materialColors = <int, Map<String, int>>{};
      for (var ink in material.inks) {
        final color = ink.visualColor;
        materialColors[ink.id] = {
          'r': (color.r * 255.0).round().clamp(0, 255),
          'g': (color.g * 255.0).round().clamp(0, 255),
          'b': (color.b * 255.0).round().clamp(0, 255),
        };
      }

      // Create PDF metadata
      final metadata = PDFMetadata(
        filename: 'blueprint_${DateTime.now().millisecondsSinceEpoch}.pdf',
        title: 'LatticeLock Security Tag Blueprint',
        batchCode: inputText.substring(0, inputText.length.clamp(0, 20)),
        algorithm: _encryptionStrategy.name,
        materialProfile: material.name,
        timestamp: DateTime.now(),
        pattern: pattern2D,
        gridSize: actualGridSize, // Explicitly pass grid size
        materialColors: materialColors,
        additionalData: {
          'inputText': inputText,
          'materialName': material.name,
          'patternLength': pattern.length,
          'totalCells': actualGridSize * actualGridSize,
        },
      );

      // Generate PDF
      final pdfResult = await pdfService.generatePDF(metadata);

      // Save to history (even if PDF generation fails, the pattern was created)
      final historyEntry = PatternHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        batchCode: metadata.batchCode,
        algorithm: metadata.algorithm,
        materialProfile: metadata.materialProfile,
        pattern: pattern2D,
        timestamp: metadata.timestamp,
        pdfPath: metadata.filename,
        metadata: {
          ...metadata.additionalData,
          'materialColors': materialColors,
          'pdfGenerationSuccess': pdfResult.success,
          'pdfError': pdfResult.error,
        },
      );

      await historyService.saveEntry(historyEntry);

      if (pdfResult.success) {
        // Download or share PDF based on platform
        await pdfService.downloadOrSharePDF(pdfResult);
      } else {
        // Pattern was still generated and saved to history
      }
    } catch (e) {
      rethrow;
    }
  }

  }

// Riverpod providers for dependency injection
final pdfServiceProvider = Provider<PDFService>((ref) {
  return PDFService.create();
});

// Global shared HistoryService instance for entire app
// This ensures the SAME instance is used by both generator and history screen
final HistoryService globalHistoryService = HistoryService.create();

final historyServiceProvider = Provider<HistoryService>((ref) {
  return globalHistoryService;
});

final generatorUseCaseProvider = Provider<GeneratorUseCase>((ref) {
  return GeneratorUseCase();
});