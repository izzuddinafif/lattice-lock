import 'dart:typed_data';
import 'pdf_service.dart';

/// Stub PDF service for testing and non-web platforms
class WebPDFServiceStub implements PDFService {
  @override
  Future<PDFResult> generatePDF(PDFMetadata metadata) async {
    // Return a mock PDF result for testing
    final mockPDFBytes = Uint8List.fromList('Mock PDF content'.codeUnits);
    return PDFResult(
      bytes: mockPDFBytes,
      metadata: metadata,
    );
  }

  @override
  Future<bool> downloadOrSharePDF(PDFResult pdfResult) async {
    // Mock download success for testing
    return true;
  }
}