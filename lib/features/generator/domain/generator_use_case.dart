import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../encryption/domain/encryption_strategy.dart';
import '../../encryption/data/chaos_strategy.dart';
import '../../encryption/data/tent_map_strategy.dart';
import '../../encryption/data/arnolds_cat_map_strategy.dart';
import '../../material/models/ink_profile.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/native_crypto_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/history_service.dart';

class GeneratorUseCase {
  EncryptionStrategy _encryptionStrategy = ChaosLogisticStrategy(); // Default strategy
  bool _useNativeCrypto = false; // Flag to use native crypto for sensitive operations
  String? _currentKeyId; // Current key ID for encryption

  /// Initialize the generator use case with native crypto
  Future<void> initialize() async {
    try {
      await NativeCryptoService.initialize();
      _currentKeyId = await NativeCryptoService.generateNewKey();
      _useNativeCrypto = await NativeCryptoService.isAvailable();
      
      if (kDebugMode) {
        print('GeneratorUseCase initialized with native crypto: $_useNativeCrypto');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize native crypto, falling back to chaos algorithms: $e');
      }
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
        // Fallback to chaos logistic map for backwards compatibility
        final chaosStrategy = ChaosLogisticStrategy();
        final encryptedPattern = chaosStrategy.encrypt(data, data.length);
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
    print('🎯 ALGORITHM SELECTION: Setting algorithm to "$algorithm"');
    switch (algorithm) {
      case 'chaos_logistic':
        print('🎯 ALGORITHM SELECTED: Chaos Logistic Strategy');
        _encryptionStrategy = ChaosLogisticStrategy();
        break;
      case 'chaos_tent':
        print('🎯 ALGORITHM SELECTED: Tent Map Strategy');
        _encryptionStrategy = TentMapStrategy();
        break;
      case 'chaos_arnolds_cat':
        print('🎯 ALGORITHM SELECTED: Arnold\'s Cat Map Strategy');
        _encryptionStrategy = ArnoldsCatMapStrategy();
        break;
      default:
        print('🎯 ALGORITHM DEFAULT: Using Chaos Logistic Strategy (unknown: $algorithm)');
        _encryptionStrategy = ChaosLogisticStrategy();
        break;
    }
    print('🎯 ALGORITHM TYPE: ${_encryptionStrategy.runtimeType}');
  }

  Future<List<int>> generatePattern({
    required String inputText,
    required String algorithm,
    int? gridSize, // Optional grid size parameter
  }) async {
    print('🚀 generatePattern() called with inputText="$inputText", algorithm="$algorithm", gridSize=$gridSize');

    // Set algorithm based on selection
    setAlgorithm(algorithm);

    // Calculate total cells based on grid size (default to 8x8 for backward compatibility)
    final totalCells = AppConstants.getTotalCells(gridSize ?? AppConstants.defaultGridSize);

    print('🚀 About to encrypt with totalCells=$totalCells');

    // Encrypt input text to pattern
    final encryptedData = _encryptionStrategy.encrypt(inputText, totalCells);

    print('🚀 Encryption complete! Pattern length=${encryptedData.length}, first_10=${encryptedData.take(10).join(',')}');
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
      final historyService = HistoryService.create();

      // Use provided grid size or default to 8x8 for backward compatibility
      final actualGridSize = gridSize ?? AppConstants.defaultGridSize;

      // Convert pattern to 2D array for compatibility
      final pattern2D = <List<int>>[];
      for (int i = 0; i < pattern.length; i += actualGridSize) {
        final end = (i + actualGridSize).clamp(0, pattern.length);
        pattern2D.add(pattern.sublist(i, end));
      }

      // Create PDF metadata
      final metadata = PDFMetadata(
        filename: 'blueprint_${DateTime.now().millisecondsSinceEpoch}.pdf',
        title: 'LatticeLock Security Tag Blueprint',
        batchCode: inputText.substring(0, inputText.length.clamp(0, 20)),
        algorithm: _encryptionStrategy.runtimeType.toString(),
        materialProfile: material.name,
        timestamp: DateTime.now(),
        pattern: pattern2D,
        additionalData: {
          'inputText': inputText,
          'materialName': material.name,
          'patternLength': pattern.length,
          'gridSize': actualGridSize,
          'totalCells': actualGridSize * actualGridSize,
        },
      );

      // Generate PDF
      final pdfResult = await pdfService.generatePDF(metadata);

      if (pdfResult.success) {
        // Save to history
        final historyEntry = PatternHistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          batchCode: metadata.batchCode,
          algorithm: metadata.algorithm,
          materialProfile: metadata.materialProfile,
          pattern: pattern2D,
          timestamp: metadata.timestamp,
          pdfPath: metadata.filename,
          metadata: metadata.additionalData,
        );

        await historyService.saveEntry(historyEntry);

        // Download or share PDF based on platform
        await pdfService.downloadOrSharePDF(pdfResult);

        if (kDebugMode) {
          print('PDF generated and saved successfully: ${metadata.filename}');
        }
      } else {
        throw Exception('PDF generation failed: ${pdfResult.error}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PDF generation error: $e');
      }
      rethrow;
    }
  }

  }

// Riverpod providers for dependency injection
final pdfServiceProvider = Provider<PDFService>((ref) {
  return PDFService.create();
});

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService.create();
});

final generatorUseCaseProvider = Provider<GeneratorUseCase>((ref) {
  return GeneratorUseCase();
});