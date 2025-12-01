import 'dart:js_interop';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart';
import 'pdf_service.dart';

/// Web PDF service implementation using browser APIs
class WebPDFService implements PDFService {
  @override
  Future<PDFResult> generatePDF(PDFMetadata metadata) async {
    try {
      // Create a basic PDF structure
      if (kIsWeb) {
        final pdfContent = _createBasicPDF(metadata);
        return PDFResult(bytes: pdfContent, metadata: metadata);
      } else {
        return PDFResult.error(metadata: metadata, error: 'Web PDF service only available on web platform');
      }
    } catch (e) {
      return PDFResult.error(metadata: metadata, error: 'PDF generation failed: $e');
    }
  }

  @override
  Future<bool> downloadOrSharePDF(PDFResult pdfResult) async {
    try {
      if (!pdfResult.success) {
        throw PDFServiceException('No PDF content to download');
      }

      if (kIsWeb) {
        // Create a simple data URL for PDF download
        final content = String.fromCharCodes(pdfResult.bytes);
        final dataUrl = 'data:application/pdf;base64,${base64Encode(pdfResult.bytes)}';
        
        // Create download link and trigger download
        final anchor = HTMLAnchorElement()
          ..href = dataUrl
          ..download = pdfResult.metadata.filename
          ..style.display = 'none';

        document.body?.appendChild(anchor);
        anchor.click();

        // Clean up
        document.body?.removeChild(anchor);

        return true;
      } else {
        throw PDFServiceException('PDF download only available on web platform');
      }
    } catch (e) {
      throw PDFServiceException('PDF download failed: $e');
    }
  }

  /// Create basic PDF content
  Uint8List _createBasicPDF(PDFMetadata metadata) {
    final List<int> pdfBytes = [];

    // PDF header
    pdfBytes.addAll('%PDF-1.4\n'.codeUnits);

    final content = _generateContent(metadata);
    pdfBytes.addAll(content.codeUnits);
    pdfBytes.addAll('\n%%EOF\n'.codeUnits);

    return Uint8List.fromList(pdfBytes);
  }

  /// Generate PDF content
  String _generateContent(PDFMetadata metadata) {
    final gridSize = metadata.additionalData['gridSize'] ?? 8;
    final pattern = _formatPatternForPDF(metadata.pattern);

    return '''
LatticeLock Security Tag Blueprint
Title: ${metadata.title}
Batch Code: ${metadata.batchCode}
Algorithm: ${metadata.algorithm}
Material Profile: ${metadata.materialProfile}
Generated: ${metadata.timestamp.toIso8601String()}
Grid Size: ${gridSize}x$gridSize
Total Cells: ${metadata.additionalData['totalCells'] ?? 'Unknown'}

Pattern Visualization:
$pattern

This PDF contains your encrypted LatticeLock security tag pattern.
Each cell represents an ink type to be used in the physical tag.
''';
  }

  /// Format pattern for PDF display
  String _formatPatternForPDF(List<List<int>> pattern) {
    if (pattern.isEmpty) return 'No pattern data available';

    final buffer = StringBuffer();
    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        buffer.write('${pattern[row][col]} ');
      }
      if (row < pattern.length - 1) buffer.write('\n');
    }
    return buffer.toString();
  }
}