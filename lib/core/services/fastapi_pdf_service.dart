import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'pdf_service.dart';

// Platform-specific imports
import 'package:path_provider/path_provider.dart';

// Web-only imports
import 'dart:html' as html;

/// FastAPI-based PDF service for professional PDF generation
class FastApiPDFService implements PDFService {
  static const String _baseUrl = String.fromEnvironment('PDF_API_BASE_URL',
      defaultValue: 'http://localhost:8001');
  static const Duration _timeout = Duration(seconds: 30);

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

      final requestData = {
        'metadata': metadataMap
      };

      // Make HTTP request to FastAPI backend
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-pdf'),
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
        // For web, create download using base64 data URL
        final pdfBase64 = base64Encode(pdfResult.bytes);
        final dataUrl = 'data:application/pdf;base64,$pdfBase64';

        // Create download link and trigger download
        final anchor = html.AnchorElement()
          ..href = dataUrl
          ..download = pdfResult.metadata.filename
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        anchor.remove();

        return true;
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
    } else {
      // For desktop, use downloads directory
      return '${Platform.environment['USERPROFILE']}\\Downloads';
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
}