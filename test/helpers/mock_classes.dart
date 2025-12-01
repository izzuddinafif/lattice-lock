import 'package:mockito/mockito.dart';
import 'package:latticelock/core/services/pdf_service.dart';
import 'package:latticelock/core/services/history_service.dart';
// import 'package:latticelock/core/services/native_crypto_service.dart'; // Unused for now
// import 'dart:typed_data'; // Unused for now

class MockPDFService extends Mock implements PDFService {}

class MockHistoryService extends Mock implements HistoryService {}

class MockNativeCryptoService extends Mock {
  // Mock static methods from NativeCryptoService for testing
  // Note: NativeCryptoService uses static methods, so these are instance methods for testing

  Future<void> initialize() async {
    // Mock implementation
  }

  bool isAvailable() {
    return true; // Mock implementation
  }

  Future<String> generateNewKey({String? keyId}) async {
    return 'mock-key-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> encryptString(String text, {String? keyId}) async {
    // Mock string encryption
    return text;
  }

  Future<String> decryptString(String encryptedText, String keyId) async {
    // Mock string decryption
    return encryptedText;
  }
}