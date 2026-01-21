import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Signature service interface for digital signatures
abstract class SignatureService {
  /// Sign data with private key (server-side)
  Future<String> sign(String data);

  /// Verify signature with public key (client-side)
  Future<bool> verify(String data, String signature);
}

/// HMAC-SHA256 signature service implementation
///
/// For research paper POC, HMAC-SHA256 provides:
/// - Simple, well-understood algorithm
/// - Symmetric key (shared secret)
/// - Industry-standard for message authentication
/// - Fast and reliable
/// - No complex key pair management
class HmacSignatureService implements SignatureService {
  final String _secretKey;
  late final List<int> _keyBytes;

  /// Create signature service with shared secret key
  HmacSignatureService(this._secretKey) {
    _keyBytes = utf8.encode(_secretKey);
  }

  /// Create from Base64-encoded secret key
  ///
  /// This factory handles raw binary keys that may not be valid UTF-8
  factory HmacSignatureService.fromBase64(String base64Key) {
    final keyBytes = base64Decode(base64Key);
    // Create a wrapper that stores bytes directly without UTF-8 conversion
    return HmacSignatureService._fromBytes(keyBytes);
  }

  /// Private constructor for binary key data
  HmacSignatureService._fromBytes(List<int> keyBytes)
      : _secretKey = base64Encode(keyBytes),
        _keyBytes = keyBytes;

  /// Generate cryptographically random secret key
  static String generateSecretKey() {
    final random = Random.secure();
    final randomBytes = List.generate(32, (i) => random.nextInt(256));
    return base64Encode(randomBytes);
  }

  @override
  Future<String> sign(String data) async {
    // Compute HMAC-SHA256
    final hmac = Hmac(sha256, _keyBytes);
    final digest = hmac.convert(utf8.encode(data));

    // Return Base64 encoded signature
    return base64Encode(digest.bytes);
  }

  @override
  Future<bool> verify(String data, String signatureBase64) async {
    try {
      // Compute expected signature
      final expectedSignature = await sign(data);

      // Compare with provided signature (constant-time comparison)
      final providedBytes = base64Decode(signatureBase64);
      final expectedBytes = base64Decode(expectedSignature);

      if (providedBytes.length != expectedBytes.length) {
        return false;
      }

      // Constant-time comparison to prevent timing attacks
      int result = 0;
      for (int i = 0; i < providedBytes.length; i++) {
        result |= providedBytes[i] ^ expectedBytes[i];
      }

      return result == 0;
    } catch (e) {
      return false;
    }
  }

  /// Export secret key as Base64 (for sharing between server and client)
  String exportSecretKeyBase64() {
    return base64Encode(_keyBytes);
  }
}

/// Key pair utilities (named for API compatibility)
class KeyPairUtils {
  /// Generate secret key and export as Base64
  static Map<String, String> generateAndExportBase64() {
    final secretKey = HmacSignatureService.generateSecretKey();
    return {
      'secretKey': secretKey,
    };
  }
}
