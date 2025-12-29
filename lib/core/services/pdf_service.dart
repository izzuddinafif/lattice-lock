import 'package:flutter/foundation.dart';
import 'fastapi_pdf_service.dart';

/// Model for PDF generation metadata
class PDFMetadata {
  final String filename;
  final String title;
  final String batchCode;
  final String algorithm;
  final String materialProfile;
  final DateTime timestamp;
  final List<List<int>> pattern;
  final int gridSize; // Explicit grid size for backend
  final Map<String, dynamic> additionalData;
  final Map<int, Map<String, int>>? materialColors; // ink ID -> {r, g, b}

  PDFMetadata({
    required this.filename,
    required this.title,
    required this.batchCode,
    required this.algorithm,
    required this.materialProfile,
    required this.timestamp,
    required this.pattern,
    required this.gridSize,
    this.additionalData = const {},
    this.materialColors,
  });

  // Helper getters for backward compatibility
  String get formattedDate {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
  }

  String get inputHash {
    return additionalData['inputHash'] ?? 'N/A';
  }
}

/// Result of PDF generation operation
class PDFResult {
  final Uint8List bytes;
  final PDFMetadata metadata;
  final bool success;
  final String? error;

  PDFResult({
    required this.bytes,
    required this.metadata,
    this.success = true,
    this.error,
  });

  PDFResult.error({
    required this.metadata,
    required this.error,
  }) : bytes = Uint8List(0), success = false;
}

/// Abstract PDF service interface for cross-platform PDF generation
abstract class PDFService {
  /// Generate PDF from pattern and metadata
  Future<PDFResult> generatePDF(PDFMetadata metadata);

  /// Download/share PDF using platform-appropriate method
  Future<bool> downloadOrSharePDF(PDFResult pdfResult);

  /// Get platform-specific service implementation
  factory PDFService.create() {
    // Use FastAPI service for all platforms now that we have a Python backend
    return FastApiPDFService();
  }
}

/// Exception thrown when PDF operations fail
class PDFServiceException implements Exception {
  final String message;
  final String? code;

  const PDFServiceException(this.message, [this.code]);

  @override
  String toString() => 'PDFServiceException: $message${code != null ? ' (code: $code)' : ''}';
}