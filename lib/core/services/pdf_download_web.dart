import 'dart:html';
import 'dart:typed_data';
import 'dart:convert';

/// Web-specific PDF download implementation using dart:html
/// This file is only compiled on web platforms due to conditional export in pdf_download.dart
class PDFDownloadWeb {
  /// Download PDF in web browser using data URL
  static Future<bool> downloadPDF(Uint8List bytes, String filename) async {
    try {
      final pdfBase64 = base64Encode(bytes);
      final dataUrl = 'data:application/pdf;base64,$pdfBase64';

      // Create download link and trigger download
      final anchor = AnchorElement()
        ..href = dataUrl
        ..download = filename
        ..style.display = 'none';

      document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();

      return true;
    } catch (e) {
      throw Exception('PDF download failed: $e');
    }
  }
}
