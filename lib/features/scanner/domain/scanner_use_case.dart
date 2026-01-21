import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// Scanner use case for image upload and pattern verification
///
/// This use case handles:
/// 1. Image upload to scanner API
/// 2. Pattern extraction from 8×8 grid
/// 3. Pattern verification against database
class ScannerUseCase {
  static const String _baseUrl = String.fromEnvironment('SCANNER_API_BASE_URL',
      defaultValue: 'http://localhost:8000');
  static const Duration _timeout = Duration(seconds: 30);

  /// Analyze uploaded image and extract pattern
  ///
  /// Returns [ImageAnalysisResult] containing:
  /// - success: Whether analysis succeeded
  /// - pattern: List of 64 ink IDs (0-4, or -1 for unknown)
  /// - extractedColors: 8×8 grid of RGB values
  /// - gridDetected: Whether 8×8 grid was detected
  /// - message: Status message
  Future<ImageAnalysisResult> analyzeImage(Uint8List imageBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/analyze-image'),
      );

      // Attach image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'scan.jpg',
        ),
      );

      // Send request
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return ImageAnalysisResult.fromJson(response.body);
      } else {
        throw ScannerException(
          'Failed to analyze image: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ScannerException('Image analysis failed: $e');
    }
  }

  /// Verify pattern against database
  ///
  /// Returns [ScannerVerificationResult] containing:
  /// - found: Whether exact match was found
  /// - matches: List of exact pattern matches
  /// - partialMatches: List of partial matches
  Future<ScannerVerificationResult> verifyPattern(
    List<int> pattern, {
    String algorithm = 'auto-detect',
    List<List<List<int>>>? extractedColors,
  }) async {
    try {
      // Validate pattern forms a perfect square grid (3x3 to 8x8)
      final gridSize = math.sqrt(pattern.length).toInt();
      if (gridSize * gridSize != pattern.length || gridSize < 3 || gridSize > 8) {
        throw ScannerException(
          'Pattern must form a square grid from 3×3 to 8×8 (got ${pattern.length} values)',
        );
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/verify-pattern'),
            headers: {'Content-Type': 'application/json'},
            body: ScannerRequest(
              pattern: pattern,
              algorithm: algorithm,
              extractedColors: extractedColors,
            ).toJson(),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ScannerVerificationResult.fromJson(response.body);
      } else {
        throw ScannerException(
          'Failed to verify pattern: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ScannerException('Pattern verification failed: $e');
    }
  }

  /// Get material profile configuration
  ///
  /// Returns [MaterialProfile] with all available inks and their colors
  Future<MaterialProfile> getMaterialProfile() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/material-profile'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return MaterialProfile.fromJson(response.body);
      } else {
        throw ScannerException(
          'Failed to get material profile: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ScannerException('Failed to fetch material profile: $e');
    }
  }
}

/// Custom exception for scanner errors
class ScannerException implements Exception {
  final String message;

  ScannerException(this.message);

  @override
  String toString() => message;
}

/// Image analysis result from scanner API
class ImageAnalysisResult {
  final bool success;
  final List<int> pattern;
  final List<List<List<int>>> extractedColors; // 3D array: [row][col][rgb]
  final bool gridDetected;
  final String message;

  ImageAnalysisResult({
    required this.success,
    required this.pattern,
    required this.extractedColors,
    required this.gridDetected,
    required this.message,
  });

  factory ImageAnalysisResult.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);

    // Parse pattern from JSON
    final List<int> pattern = json['pattern'] != null
        ? List<int>.from(json['pattern'])
        : [];

    // Parse extracted_colors from JSON (backend uses snake_case)
    // Backend sends: [[row][col][rgb]] - 3D array with 8 rows × 8 cols × 3 RGB values
    final List<List<List<int>>> extractedColors = json['extracted_colors'] != null
        ? List<List<List<int>>>.from(
            json['extracted_colors'].map(
              (row) => List<List<int>>.from(
                row.map(
                  (rgb) => List<int>.from(rgb),
                ),
              ),
            ),
          )
        : [];

    return ImageAnalysisResult(
      success: json['success'] ?? false,
      pattern: pattern,
      extractedColors: extractedColors,
      gridDetected: json['grid_detected'] ?? false, // Backend uses snake_case
      message: json['message'] ?? '',
    );
  }
}

/// Scanner verification request
class ScannerRequest {
  final List<int> pattern;
  final String algorithm;
  final List<List<List<int>>>? extractedColors;

  ScannerRequest({
    required this.pattern,
    this.algorithm = 'auto-detect',
    this.extractedColors,
  });

  String toJson() {
    // JSON serialization with extracted_colors support
    if (extractedColors != null) {
      return '{"pattern": $pattern, "algorithm": "$algorithm", "extracted_colors": $extractedColors}';
    }
    return '{"pattern": $pattern, "algorithm": "$algorithm"}';
  }
}

/// Scanner verification result
class ScannerVerificationResult {
  final bool found;
  final List<PatternMatch> matches;
  final List<Map<String, dynamic>> partialMatches;

  ScannerVerificationResult({
    required this.found,
    required this.matches,
    required this.partialMatches,
  });

  factory ScannerVerificationResult.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);

    // Parse matches list
    final List<PatternMatch> matches = json['matches'] != null
        ? List<Map<String, dynamic>>.from(json['matches'])
            .map((matchJson) => PatternMatch.fromJson(matchJson))
            .toList()
        : [];

    // Parse partial_matches (backend uses snake_case)
    final List<Map<String, dynamic>> partialMatches = json['partial_matches'] != null
        ? List<Map<String, dynamic>>.from(json['partial_matches'])
        : [];

    return ScannerVerificationResult(
      found: json['found'] ?? false,
      matches: matches,
      partialMatches: partialMatches,
    );
  }
}

/// Pattern match result
class PatternMatch {
  final String id;
  final String inputText;
  final String algorithm;
  final String timestamp;
  final double confidence;

  PatternMatch({
    required this.id,
    required this.inputText,
    required this.algorithm,
    required this.timestamp,
    required this.confidence,
  });

  factory PatternMatch.fromJson(Map<String, dynamic> json) {
    return PatternMatch(
      id: json['id']?.toString() ?? '',
      inputText: json['inputText']?.toString() ?? '',
      algorithm: json['algorithm']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Material profile with ink definitions
class MaterialProfile {
  final String name;
  final List<MaterialInk> inks;

  MaterialProfile({
    required this.name,
    required this.inks,
  });

  factory MaterialProfile.fromJson(String jsonString) {
    // Parse from JSON
    return MaterialProfile(
      name: 'Standard',
      inks: [],
    );
  }
}

/// Material ink definition
class MaterialInk {
  final int id;
  final String name;
  final RGBColor visualColor;
  final double? temperature;
  final String? description;

  MaterialInk({
    required this.id,
    required this.name,
    required this.visualColor,
    this.temperature,
    this.description,
  });
}

/// RGB color representation
class RGBColor {
  final int r;
  final int g;
  final int b;

  RGBColor({
    required this.r,
    required this.g,
    required this.b,
  });
}
