import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'pdf_service.dart';

// Platform-specific imports
import 'package:path_provider/path_provider.dart';

// Conditional import for web-specific PDF download
// Exports web implementation on web, stub implementation otherwise
import 'pdf_download.dart';

/// FastAPI-based PDF service for professional PDF generation
class FastApiPDFService implements PDFService {
  static const String _baseUrl = String.fromEnvironment('PDF_API_BASE_URL',
      defaultValue: 'http://localhost:8000');
  static const Duration _timeout = Duration(seconds: 30);

  /// Get the base URL for API requests
  /// For web with relative base URL, construct from current origin
  String _getEffectiveBaseUrl() {
    if (_baseUrl == '/' || _baseUrl.isEmpty) {
      // Use relative path - browser will use current origin
      return '';
    }
    return _baseUrl;
  }

  @override
  Future<PDFResult> generatePDF(PDFMetadata metadata) async {
    try {
      // Prepare the request data matching the FastAPI backend format
      // Convert Map<int, Map<String, int>> to Map<String, Map<String, int>> for JSON
      final materialColorsJson = metadata.materialColors?.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      // Build metadata map
      final metadataMap = {
        'filename': metadata.filename,
        'title': metadata.title,
        'batch_code': metadata.batchCode,
        'algorithm': metadata.algorithm,
        'material_profile': metadata.materialProfile,
        'timestamp': metadata.timestamp.toIso8601String(),
        'pattern': metadata.pattern,
        'grid_size': metadata.gridSize,
      };

      // Add material_colors if available
      if (materialColorsJson != null) {
        metadataMap['material_colors'] = materialColorsJson;
      }

      // Add signature fields if available
      if (metadata.signature != null && metadata.signature!.isNotEmpty) {
        metadataMap['signature'] = metadata.signature!;
      }
      if (metadata.patternHash != null && metadata.patternHash!.isNotEmpty) {
        metadataMap['pattern_hash'] = metadata.patternHash!;
      }
      if (metadata.manufacturerId != null && metadata.manufacturerId!.isNotEmpty) {
        metadataMap['manufacturer_id'] = metadata.manufacturerId!;
      }
      if (metadata.numInks != null) {
        metadataMap['num_inks'] = metadata.numInks!;
      }

      final requestData = {
        'metadata': metadataMap
      };

      // Build URI - use relative path for web deployment
      final effectiveBaseUrl = _getEffectiveBaseUrl();
      final uri = Uri.parse('$effectiveBaseUrl/generate-pdf');

      // Make HTTP request to FastAPI backend
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['success'] == true) {
          final pdfBase64 = responseData['pdf_base64'] as String;

          // Convert base64 to bytes (handle both raw base64 and data URL format)
          final base64Data = pdfBase64.contains(',') ? pdfBase64.split(',')[1] : pdfBase64;
          final pdfBytes = base64.decode(base64Data);

          return PDFResult(
            bytes: pdfBytes,
            metadata: metadata,
            success: true,
          );
        } else {
          return PDFResult.error(
            metadata: metadata,
            error: responseData['error'] as String? ?? 'Unknown error occurred',
          );
        }
      } else {
        return PDFResult.error(
          metadata: metadata,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return PDFResult.error(
        metadata: metadata,
        error: 'PDF generation failed: $e',
      );
    }
  }

  @override
  Future<bool> downloadOrSharePDF(PDFResult pdfResult) async {
    try {
      if (!pdfResult.success) {
        throw PDFServiceException('No PDF content to download');
      }

      if (kIsWeb) {
        // For web, use platform-specific download implementation
        return await PDFDownloadWeb.downloadPDF(pdfResult.bytes, pdfResult.metadata.filename);
      } else {
        // For mobile/desktop, save to file system
        final directory = await getDownloadsDirectory();
        final filePath = '$directory/${pdfResult.metadata.filename}';
        final file = File(filePath);
        await file.writeAsBytes(pdfResult.bytes);

        return true;
      }
    } catch (e) {
      throw PDFServiceException('PDF download failed: $e');
    }
  }

  /// Get downloads directory for mobile/desktop
  Future<String> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use external storage
      return '/storage/emulated/0/Download';
    } else if (Platform.isIOS) {
      // For iOS, use documents directory
      return (await getApplicationDocumentsDirectory()).path;
    } else if (Platform.isWindows) {
      // For Windows desktop
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return '$userProfile\\Downloads';
      }
      // Fallback
      return '.\\Downloads';
    } else if (Platform.isLinux || Platform.isMacOS) {
      // For Linux/macOS desktop
      final home = Platform.environment['HOME'];
      if (home != null) {
        return '$home/Downloads';
      }
      // Fallback
      return './Downloads';
    } else {
      // Unknown platform - fallback to current directory
      return '.';
    }
  }

  /// Check if FastAPI backend is available
  Future<bool> isBackendAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Store pattern in database for scanner verification
  Future<bool> storePattern(PDFMetadata metadata) async {
    try {
      // Prepare the request data matching the FastAPI backend format
      final materialColorsJson = metadata.materialColors?.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      // Build metadata map
      final metadataMap = {
        'filename': metadata.filename,
        'title': metadata.title,
        'batch_code': metadata.batchCode,
        'algorithm': metadata.algorithm,
        'material_profile': metadata.materialProfile,
        'timestamp': metadata.timestamp.toIso8601String(),
        'pattern': metadata.pattern,
        'grid_size': metadata.gridSize,
      };

      // Add optional fields
      if (materialColorsJson != null) {
        metadataMap['material_colors'] = materialColorsJson;
      }
      if (metadata.signature != null && metadata.signature!.isNotEmpty) {
        metadataMap['signature'] = metadata.signature!;
      }
      if (metadata.patternHash != null && metadata.patternHash!.isNotEmpty) {
        metadataMap['pattern_hash'] = metadata.patternHash!;
      }
      if (metadata.manufacturerId != null && metadata.manufacturerId!.isNotEmpty) {
        metadataMap['manufacturer_id'] = metadata.manufacturerId!;
      }
      if (metadata.numInks != null) {
        metadataMap['num_inks'] = metadata.numInks!;
      }
      if (metadata.additionalData != null) {
        metadataMap['additional_data'] = metadata.additionalData;
      }

      final requestData = {
        'metadata': metadataMap
      };

      // Make HTTP request to store pattern endpoint
      final response = await http.post(
        Uri.parse('$_baseUrl/store-pattern'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final success = responseData['success'] as bool? ?? false;

        if (success) {
          print('✓ Pattern stored in database: ${responseData['uuid']}');
          return true;
        } else {
          print('✗ Failed to store pattern: ${responseData['error']}');
          return false;
        }
      } else {
        print('✗ HTTP ${response.statusCode} storing pattern: ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      print('✗ Exception storing pattern: $e');
      // Don't throw - storage failure shouldn't break PDF generation
      return false;
    }
  }
}