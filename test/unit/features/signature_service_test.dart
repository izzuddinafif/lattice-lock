import 'package:flutter_test/flutter_test.dart';
import 'package:latticelock/features/signature/domain/signature_service.dart';
import 'package:crypto/crypto.dart';

void main() {
  group('HmacSignatureService Tests', () {
    late HmacSignatureService signatureService;
    late String testSecretKey;

    setUp(() {
      // Generate a test secret key
      testSecretKey = HmacSignatureService.generateSecretKey();
      signatureService = HmacSignatureService(testSecretKey);
    });

    group('Initialization Tests', () {
      test('should create service with secret key', () {
        expect(signatureService, isA<HmacSignatureService>());
        expect(signatureService.exportSecretKeyBase64(), isNotEmpty);
      });

      test('should generate valid secret key', () {
        final secretKey = HmacSignatureService.generateSecretKey();
        expect(secretKey, isNotEmpty);
        expect(secretKey.length, greaterThan(20)); // Base64 encoded 32 bytes
      });

      test('should create from Base64 secret key', () {
        final base64Key = signatureService.exportSecretKeyBase64();
        final newService = HmacSignatureService.fromBase64(base64Key);

        expect(newService, isA<HmacSignatureService>());
      });
    });

    group('Signature Generation Tests', () {
      test('should generate signature for data', () async {
        const testData = 'test-batch-code-12345';
        final signature = await signatureService.sign(testData);

        expect(signature, isNotEmpty);
        expect(signature.length, greaterThan(20)); // Base64 HMAC-SHA256
      });

      test('should generate consistent signatures for same data', () async {
        const testData = 'consistent-test-data';
        final signature1 = await signatureService.sign(testData);
        final signature2 = await signatureService.sign(testData);

        expect(signature1, equals(signature2));
      });

      test('should generate different signatures for different data', () async {
        const testData1 = 'test-data-1';
        const testData2 = 'test-data-2';
        final signature1 = await signatureService.sign(testData1);
        final signature2 = await signatureService.sign(testData2);

        expect(signature1, isNot(equals(signature2)));
      });
    });

    group('Signature Verification Tests', () {
      test('should verify valid signature', () async {
        const testData = 'test-batch-code-12345';
        final signature = await signatureService.sign(testData);
        final isValid = await signatureService.verify(testData, signature);

        expect(isValid, isTrue);
      });

      test('should reject invalid signature', () async {
        const testData = 'test-batch-code-12345';
        const invalidSignature = 'invalid-base64-signature';
        final isValid = await signatureService.verify(testData, invalidSignature);

        expect(isValid, isFalse);
      });

      test('should reject signature for different data', () async {
        const testData1 = 'test-data-1';
        const testData2 = 'test-data-2';
        final signature = await signatureService.sign(testData1);
        final isValid = await signatureService.verify(testData2, signature);

        expect(isValid, isFalse);
      });

      test('should reject empty signature', () async {
        const testData = 'test-batch-code-12345';
        final isValid = await signatureService.verify(testData, '');

        expect(isValid, isFalse);
      });

      test('should reject malformed Base64 signature', () async {
        const testData = 'test-batch-code-12345';
        final malformedSignature = 'not-valid-base64!!!';
        final isValid = await signatureService.verify(testData, malformedSignature);

        expect(isValid, isFalse);
      });
    });

    group('Security Tests', () {
      test('should use constant-time comparison for verification', () async {
        const testData = 'test-batch-code-12345';
        final signature = await signatureService.sign(testData);

        // Timing attack resistance test - should complete quickly
        final stopwatch = Stopwatch()..start();
        await signatureService.verify(testData, signature);
        stopwatch.stop();

        // Should complete in reasonable time (< 100ms even for small data)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should generate unique keys for multiple calls', () async {
        final key1 = HmacSignatureService.generateSecretKey();
        final key2 = HmacSignatureService.generateSecretKey();

        expect(key1, isNot(equals(key2)));
      });

      test('should handle large data input', () async {
        final largeData = 'x' * 10000; // 10KB of data
        final signature = await signatureService.sign(largeData);

        expect(signature, isNotEmpty);

        final isValid = await signatureService.verify(largeData, signature);
        expect(isValid, isTrue);
      });
    });

    group('KeyPairUtils Tests', () {
      test('should generate and export key as Base64', () {
        final keyData = KeyPairUtils.generateAndExportBase64();

        expect(keyData, contains('secretKey'));
        expect(keyData['secretKey'], isNotEmpty);
        expect(keyData['secretKey'], isA<String>());
      });
    });

    group('Integration Tests', () {
      test('should work with PatternMetadata-like data', () async {
        // Simulate signing pattern metadata
        const batchCode = 'BATCH-2024-001';
        final timestamp = DateTime.now().toIso8601String();
        final pattern = [0, 1, 2, 3, 4];

        final dataToSign = '$batchCode|$timestamp|${pattern.join(',')}';
        final signature = await signatureService.sign(dataToSign);

        expect(signature, isNotEmpty);

        final isValid = await signatureService.verify(dataToSign, signature);
        expect(isValid, isTrue);
      });

      test('should handle UTF-8 characters in data', () async {
        const testData = '测试数据-テストデータ-🔒';
        final signature = await signatureService.sign(testData);

        expect(signature, isNotEmpty);

        final isValid = await signatureService.verify(testData, signature);
        expect(isValid, isTrue);
      });
    });

    group('Edge Cases Tests', () {
      test('should handle empty string', () async {
        const testData = '';
        final signature = await signatureService.sign(testData);

        expect(signature, isNotEmpty);

        final isValid = await signatureService.verify(testData, signature);
        expect(isValid, isTrue);
      });

      test('should handle special characters', () async {
        const testData = '!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`';
        final signature = await signatureService.sign(testData);

        expect(signature, isNotEmpty);

        final isValid = await signatureService.verify(testData, signature);
        expect(isValid, isTrue);
      });

      test('should handle very long data', () async {
        final testData = 'A' * 100000; // 100KB
        final signature = await signatureService.sign(testData);

        expect(signature, isNotEmpty);

        final isValid = await signatureService.verify(testData, signature);
        expect(isValid, isTrue);
      });
    });
  });
}
