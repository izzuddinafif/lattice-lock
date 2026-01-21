import 'dart:typed_data';

/// Stub implementation for non-web platforms
class PDFDownloadWeb {
  /// This should never be called on non-web platforms
  static Future<bool> downloadPDF(Uint8List bytes, String filename) async {
    throw UnimplementedError('Web download not available on this platform');
  }
}
