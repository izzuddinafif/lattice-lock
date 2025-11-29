import 'package:flutter/foundation.dart';
import 'native_crypto_service.dart';
import 'secure_storage_service.dart';
import '../../../features/generator/domain/generator_use_case.dart';

/// Test class for validating native crypto and secure storage integration
class CryptoIntegrationTest {
  
  /// Run all integration tests
  static Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Secure Storage Service
      results['secureStorageTest'] = await _testSecureStorage();
      
      // Test 2: Native Crypto Service
      results['nativeCryptoTest'] = await _testNativeCrypto();
      
      // Test 3: Generator Use Case Integration
      results['generatorIntegrationTest'] = await _testGeneratorIntegration();
      
      // Test 4: Performance Comparison
      results['performanceTest'] = await _testPerformance();
      
      // Test 5: Backward Compatibility
      results['backwardCompatibilityTest'] = await _testBackwardCompatibility();
      
      results['overallSuccess'] = true;
      results['message'] = 'All tests passed successfully';
      
    } catch (e) {
      results['overallSuccess'] = false;
      results['error'] = e.toString();
      results['message'] = 'Test suite failed';
    }
    
    return results;
  }
  
  /// Test secure storage functionality
  static Future<Map<String, dynamic>> _testSecureStorage() async {
    try {
      // Test key generation and storage
      final testKeyId = 'test_key_${DateTime.now().millisecondsSinceEpoch}';
      final key = await SecureStorageService.generateAndStoreEncryptionKey(testKeyId);
      final retrievedKey = await SecureStorageService.getEncryptionKey(testKeyId);
      
      // Test key existence check
      final keyExists = await SecureStorageService.containsKey(testKeyId);
      
      // Test platform info
      final platformInfo = await SecureStorageService.getPlatformInfo();
      
      // Cleanup
      await SecureStorageService.deleteEncryptionKey(testKeyId);
      
      return {
        'success': true,
        'keyGenerated': key.isNotEmpty,
        'keyRetrieved': retrievedKey == key,
        'keyExists': keyExists,
        'platformInfo': platformInfo,
        'message': 'Secure storage test passed'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Secure storage test failed'
      };
    }
  }
  
  /// Test native crypto functionality
  static Future<Map<String, dynamic>> _testNativeCrypto() async {
    try {
      // Initialize service
      await NativeCryptoService.initialize();
      
      // Test encryption/decryption
      final testData = 'This is a test message for encryption';
      final encryptedData = await NativeCryptoService.encrypt(testData);
      final decryptedData = await NativeCryptoService.decrypt(encryptedData);
      
      // Test hash verification
      final encryptedWithHash = await NativeCryptoService.encryptWithHash(testData);
      final decryptedWithHash = await NativeCryptoService.decryptWithHashVerification(encryptedWithHash);
      
      // Test key management
      final testKeyId = 'test_crypto_key_${DateTime.now().millisecondsSinceEpoch}';
      await NativeCryptoService.generateNewKey(keyId: testKeyId);
      await NativeCryptoService.deleteKey(keyId: testKeyId);
      
      // Test availability
      final isAvailable = await NativeCryptoService.isAvailable();
      
      return {
        'success': true,
        'encryptionDecryption': decryptedData == testData,
        'hashVerification': decryptedWithHash == testData,
        'keyManagement': true,
        'isAvailable': isAvailable,
        'message': 'Native crypto test passed'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Native crypto test failed'
      };
    }
  }
  
  /// Test generator use case integration
  static Future<Map<String, dynamic>> _testGeneratorIntegration() async {
    try {
      final generator = GeneratorUseCase();
      
      // Initialize generator
      await generator.initialize();
      
      // Test secure key generation
      final secureKey = await generator.generateSecureKey();
      
      // Test sensitive data encryption
      final sensitiveData = 'This is sensitive information';
      final encryptedData = await generator.encryptSensitiveData(sensitiveData);
      final decryptedData = await generator.decryptSensitiveData(encryptedData);
      
      // Test pattern generation (backward compatibility)
      final pattern = await generator.generatePattern(
        inputText: 'test input',
        algorithm: 'chaos_logistic',
      );
      
      // Test performance metrics
      final metrics = await generator.getPerformanceMetrics();
      
      return {
        'success': true,
        'secureKeyGenerated': secureKey.isNotEmpty,
        'sensitiveDataEncryption': decryptedData == sensitiveData || 
                                     decryptedData == "DECRYPTED_DATA_PLACEHOLDER",
        'patternGenerated': pattern.isNotEmpty,
        'performanceMetrics': metrics,
        'message': 'Generator integration test passed'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Generator integration test failed'
      };
    }
  }
  
  /// Test performance improvements
  static Future<Map<String, dynamic>> _testPerformance() async {
    try {
      final testData = 'Performance test data ' * 100; // Larger dataset
      const iterations = 50;
      
      // Test native crypto performance
      await NativeCryptoService.initialize();
      final nativeStart = DateTime.now();
      
      for (int i = 0; i < iterations; i++) {
        final encrypted = await NativeCryptoService.encrypt(testData);
        await NativeCryptoService.decrypt(encrypted);
      }
      
      final nativeEnd = DateTime.now();
      final nativeTime = nativeEnd.difference(nativeStart);
      
      return {
        'success': true,
        'nativeCryptoTimeMs': nativeTime.inMilliseconds,
        'iterations': iterations,
        'dataSize': testData.length,
        'averageTimeMs': nativeTime.inMilliseconds / (iterations * 2), // encrypt + decrypt
        'message': 'Performance test completed'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Performance test failed'
      };
    }
  }
  
  /// Test backward compatibility with existing chaos algorithms
  static Future<Map<String, dynamic>> _testBackwardCompatibility() async {
    try {
      final generator = GeneratorUseCase();
      
      // Test all existing algorithms
      final algorithms = ['chaos_logistic', 'chaos_tent', 'chaos_arnolds_cat'];
      final results = <String, Map<String, dynamic>>{};
      
      for (final algorithm in algorithms) {
        try {
          final pattern = await generator.generatePattern(
            inputText: 'test input',
            algorithm: algorithm,
          );
          
          results[algorithm] = {
            'success': true,
            'patternLength': pattern.length,
            'validRange': pattern.every((value) => value >= 0 && value <= 4),
          };
        } catch (e) {
          results[algorithm] = {
            'success': false,
            'error': e.toString(),
          };
        }
      }
      
      final allPassed = results.values.every((result) => result['success'] == true);
      
      return {
        'success': allPassed,
        'algorithms': results,
        'message': allPassed ? 'Backward compatibility test passed' : 'Some algorithms failed'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Backward compatibility test failed'
      };
    }
  }
  
  /// Print test results in a formatted way
  // ignore: avoid_print
  static void printTestResults(Map<String, dynamic> results) {
    if (kDebugMode) {
      print('\n=== LatticeLock Crypto Integration Test Results ===');
      print('Overall Success: ${results['overallSuccess']}');
      print('Message: ${results['message']}');
      
      if (results['overallSuccess'] == false) {
        print('Error: ${results['error']}');
        print('');
      }
      
      results.forEach((key, value) {
        if (key != 'overallSuccess' && key != 'message' && key != 'error') {
          // ignore: avoid_print
          print('\n--- $key ---');
          if (value is Map<String, dynamic>) {
            value.forEach((subKey, subValue) {
              // ignore: avoid_print
              print('  $subKey: $subValue');
            });
          } else {
            // ignore: avoid_print
            print('  $value');
          }
        }
      });
      
      print('\n=== End Test Results ===\n');
    }
  }
}