import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../pattern/domain/pattern_generation_strategy.dart';
import '../../pattern/data/hybrid_chaotic_pattern.dart';
import '../../material/models/ink_profile.dart';
import '../../signature/domain/signature_service.dart';
import '../../signature/domain/secure_pattern_generator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/models/signed_pattern.dart';

class GeneratorUseCase {
  PatternGenerationStrategy _patternStrategy = HybridChaoticPattern();
  SecurePatternGenerator? _securePatternGenerator;
  final HistoryService _historyService;
  final PDFService _pdfService;

  GeneratorUseCase({
    HistoryService? historyService,
    PDFService? pdfService,
  })  : _historyService = historyService ?? HistoryService.create(),
        _pdfService = pdfService ?? PDFService.create();

  /// Initialize with optional signature service
  Future<void> initialize({SignatureService? signatureService}) async {
    if (signatureService != null) {
      _securePatternGenerator = SecurePatternGenerator(
        signatureService: signatureService,
        patternStrategy: _patternStrategy,
      );
    }
  }

  /// Generate spatial deposition pattern from batch code
  Future<List<int>> generatePattern({
    required String inputText,
    required String algorithm,
    int? gridSize,
    int? numInks,
  }) async {
    // Calculate total cells based on grid size
    final totalCells = AppConstants.getTotalCells(gridSize ?? AppConstants.defaultGridSize);

    // Generate pattern from batch code
    final pattern = _patternStrategy.generatePattern(
      inputText,
      totalCells,
      numInks ?? 3,
    );

    // DEBUG: Log generated pattern for verification
    debugPrint('=== PATTERN GENERATION DEBUG ===');
    debugPrint('Input: $inputText');
    debugPrint('Algorithm: $algorithm');
    debugPrint('Grid size: ${gridSize ?? AppConstants.defaultGridSize}');
    debugPrint('Pattern (64 values): $pattern');
    debugPrint('Pattern (first 16): ${pattern.take(16).toList()}');
    debugPrint('================================');

    return pattern;
  }

  /// Generate signed pattern (requires signature service)
  Future<SignedPattern?> generateSignedPattern({
    required String inputText,
    required int gridSize,
    int? numInks,
  }) async {
    if (_securePatternGenerator == null) {
      throw Exception(
        'Signature service not initialized. '
        'Use initialize(signatureService: ...) first.'
      );
    }

    return await _securePatternGenerator!.generatePattern(
      batchCode: inputText,
      gridSize: gridSize,
      numInks: numInks ?? 3,
    );
  }

  /// Generate PDF blueprint from pattern
  Future<void> generatePDF({
    required List<int> pattern,
    required MaterialProfile material,
    required String inputText,
    int? gridSize,
    SignedPattern? signedPattern,
  }) async {
    final actualGridSize = gridSize ?? AppConstants.defaultGridSize;

    // Convert pattern to 2D array
    final pattern2D = <List<int>>[];
    for (int i = 0; i < pattern.length; i += actualGridSize) {
      final end = (i + actualGridSize).clamp(0, pattern.length);
      pattern2D.add(pattern.sublist(i, end));
    }

    // Extract material colors
    final materialColors = <int, Map<String, int>>{};
    for (var ink in material.inks) {
      final color = ink.visualColor;
      materialColors[ink.id] = {
        'r': (color.r * 255.0).round().clamp(0, 255),
        'g': (color.g * 255.0).round().clamp(0, 255),
        'b': (color.b * 255.0).round().clamp(0, 255),
      };
    }

    // Create PDF metadata
    final metadata = PDFMetadata(
      filename: 'blueprint_${DateTime.now().millisecondsSinceEpoch}.pdf',
      title: 'LatticeLock Security Tag Blueprint',
      batchCode: inputText.substring(0, inputText.length.clamp(0, 20)),
      algorithm: _patternStrategy.name,
      materialProfile: material.name,
      timestamp: DateTime.now(),
      pattern: pattern2D,
      gridSize: actualGridSize,
      materialColors: materialColors,
      // Add signature fields if available
      signature: signedPattern?.signature,
      patternHash: signedPattern?.metadata.patternHash,
      manufacturerId: signedPattern?.metadata.manufacturerId,
      numInks: material.inks.length,
      additionalData: {
        'inputText': inputText,
        'materialName': material.name,
        'patternLength': pattern.length,
        'totalCells': actualGridSize * actualGridSize,
        if (signedPattern != null) ...{
          'signatureTimestamp': signedPattern.metadata.timestamp,
        },
      },
    );

    // Generate PDF
    final pdfResult = await _pdfService.generatePDF(metadata);

    // Save to history
    final historyEntry = PatternHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      batchCode: metadata.batchCode,
      algorithm: metadata.algorithm,
      materialProfile: metadata.materialProfile,
      pattern: pattern2D,
      timestamp: metadata.timestamp,
      pdfPath: metadata.filename,
      metadata: {
        ...metadata.additionalData,
        'materialColors': materialColors,
        'pdfGenerationSuccess': pdfResult.success,
        'pdfError': pdfResult.error,
      },
    );

    await _historyService.saveEntry(historyEntry);

    // Store pattern in database for scanner verification
    if (pdfResult.success) {
      await _pdfService.storePattern(metadata);
    }

    if (pdfResult.success) {
      await _pdfService.downloadOrSharePDF(pdfResult);
    }
  }
}

// Riverpod providers
final pdfServiceProvider = Provider<PDFService>((ref) => PDFService.create());

final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService.create());

final generatorUseCaseProvider = Provider<GeneratorUseCase>((ref) {
  return GeneratorUseCase(
    historyService: ref.read(historyServiceProvider),
    pdfService: ref.read(pdfServiceProvider),
  );
});
