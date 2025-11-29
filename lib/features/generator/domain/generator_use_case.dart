import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../../encryption/domain/encryption_strategy.dart';
import '../../encryption/data/chaos_strategy.dart';
import '../../encryption/data/tent_map_strategy.dart';
import '../../encryption/data/arnolds_cat_map_strategy.dart';
import '../../material/models/ink_profile.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/native_crypto_service.dart';

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
    switch (algorithm) {
      case 'chaos_logistic':
        _encryptionStrategy = ChaosLogisticStrategy();
        break;
      case 'chaos_tent':
        _encryptionStrategy = TentMapStrategy();
        break;
      case 'chaos_arnolds_cat':
        _encryptionStrategy = ArnoldsCatMapStrategy();
        break;
      default:
        _encryptionStrategy = ChaosLogisticStrategy();
        break;
    }
  }

  Future<List<int>> generatePattern({
    required String inputText,
    required String algorithm,
  }) async {
    // Set algorithm based on selection
    setAlgorithm(algorithm);

    // Encrypt input text to pattern
    final encryptedData = _encryptionStrategy.encrypt(inputText, AppConstants.totalCells);
    return encryptedData;
  }

  Future<void> generatePDF({
    required List<int> pattern,
    required MaterialProfile material,
    required String inputText,
  }) async {
    final pdf = pw.Document();
    
    // Create the blueprint page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'LatticeLock Security Tag Blueprint',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              
              // Information section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Input: $inputText', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('Material: ${material.name}', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('Generated: ${DateTime.now().toIso8601String()}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Grid pattern
              _buildGridPattern(pattern, material),
              pw.SizedBox(height: 20),
              
              // Material reference
              _buildMaterialReference(material),
            ],
          );
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final blueprintDir = Directory('${directory.path}/${AppConstants.pdfOutputFolder}');
    if (!await blueprintDir.exists()) {
      await blueprintDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'blueprint_$timestamp.pdf';
    final file = File('${blueprintDir.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());

    // Optional: Add logging for development only
    if (kDebugMode) {
      print('PDF generated: ${file.path}');
    }
  }

  pw.Widget _buildGridPattern(List<int> pattern, MaterialProfile material) {
    return pw.Container(
      width: 400,
      height: 400,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.GridView(
        crossAxisCount: AppConstants.gridSize,
        childAspectRatio: 1,
        children: pattern.map((inkId) {
          final ink = material.inks[inkId];
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: _convertToPdfColor(ink.visualColor),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Center(
              child: pw.Text(
                ink.label,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildMaterialReference(MaterialProfile material) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Material Reference',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...material.inks.map((ink) => pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: _convertToPdfColor(ink.visualColor),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text('${ink.label}: ${ink.name}', style: const pw.TextStyle(fontSize: 10)),
            ],
          )),
        ],
      ),
    );
  }

  PdfColor _convertToPdfColor(Color flutterColor) {
    return PdfColor(
      (flutterColor.r * 255.0).round().clamp(0, 255) / 255,
      (flutterColor.g * 255.0).round().clamp(0, 255) / 255,
      (flutterColor.b * 255.0).round().clamp(0, 255) / 255,
    );
  }
}