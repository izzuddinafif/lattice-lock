import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:latticelock/core/services/pdf_service.dart';
import 'package:latticelock/core/services/history_service.dart';
import 'package:latticelock/features/material/models/ink_profile.dart';
import 'mock_classes.dart';

/// Test utilities for creating test data
class TestDataFactory {
  /// Create a test PDF metadata
  static PDFMetadata createTestPDFMetadata({
    String? filename,
    String? title,
    String? batchCode,
    String? algorithm,
    String? materialProfile,
    DateTime? timestamp,
    List<List<int>>? pattern,
    int? gridSize,
    Map<String, dynamic>? additionalData,
  }) {
    return PDFMetadata(
      filename: filename ?? 'test_blueprint.pdf',
      title: title ?? 'Test Blueprint',
      batchCode: batchCode ?? 'TEST001',
      algorithm: algorithm ?? 'chaos_logistic',
      materialProfile: materialProfile ?? 'UV Ink',
      timestamp: timestamp ?? DateTime.now(),
      pattern: pattern ?? createTestPattern(),
      gridSize: gridSize ?? 8,
      additionalData: additionalData ?? {'test': true},
    );
  }

  /// Create a test PDF result
  static PDFResult createTestPDFResult({
    PDFMetadata? metadata,
    Uint8List? bytes,
    bool success = true,
    String? error,
  }) {
    return PDFResult(
      bytes: success
          ? (bytes ?? Uint8List.fromList([1, 2, 3, 4]))
          : Uint8List(0), // Empty bytes for error results
      metadata: metadata ?? createTestPDFMetadata(),
      success: success,
      error: error,
    );
  }

  /// Create a test pattern history entry
  static PatternHistoryEntry createTestHistoryEntry({
    String? id,
    String? batchCode,
    String? algorithm,
    String? materialProfile,
    List<List<int>>? pattern,
    DateTime? timestamp,
    String? pdfPath,
    Map<String, dynamic>? metadata,
  }) {
    return PatternHistoryEntry(
      id: id ?? 'test_id_001',
      batchCode: batchCode ?? 'TEST001',
      algorithm: algorithm ?? 'chaos_logistic',
      materialProfile: materialProfile ?? 'UV Ink',
      pattern: pattern ?? [[1, 0], [0, 1]],
      timestamp: timestamp ?? DateTime.now(),
      pdfPath: pdfPath ?? 'test.pdf',
      metadata: metadata ?? {'test': true},
    );
  }

  /// Create a test pattern grid
  static List<List<int>> createTestPattern({int gridSize = 8}) {
    return List.generate(
      gridSize,
      (i) => List.generate(
        gridSize,
        (j) => (i + j) % 2 == 0 ? 1 : 0,
      ),
    );
  }

  /// Create a test flattened pattern
  static List<int> createTestFlattenedPattern({int gridSize = 8}) {
    final pattern2D = createTestPattern(gridSize: gridSize);
    return pattern2D.expand((row) => row).toList();
  }

  /// Create a test history filter
  static HistoryFilter createTestHistoryFilter({
    String? batchCode,
    String? algorithm,
    String? materialProfile,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return HistoryFilter(
      batchCode: batchCode,
      algorithm: algorithm,
      materialProfile: materialProfile,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Create a test material profile
  static MaterialProfile createTestMaterialProfile({
    String? name,
  }) {
    return MaterialProfile(
      name: name ?? 'Standard Test Set',
      inks: MaterialProfile.standardSet.inks,
    );
  }
}

/// Test assertions for common patterns
class TestAssertions {
  /// Assert PDF metadata is valid
  static void assertPDFMetadataValid(PDFMetadata metadata) {
    expect(metadata.filename, isNotEmpty);
    expect(metadata.title, isNotEmpty);
    expect(metadata.batchCode, isNotEmpty);
    expect(metadata.algorithm, isNotEmpty);
    expect(metadata.materialProfile, isNotEmpty);
    expect(metadata.timestamp, isNotNull);
    expect(metadata.pattern, isNotEmpty);
    expect(metadata.pattern.every((row) => row.isNotEmpty), isTrue);
  }

  /// Assert PDF result is successful
  static void assertPDFResultSuccess(PDFResult result) {
    expect(result.success, isTrue);
    expect(result.bytes, isNotEmpty);
    expect(result.error, isNull);
    assertPDFMetadataValid(result.metadata);
  }

  /// Assert PDF result is error
  static void assertPDFResultError(PDFResult result) {
    expect(result.success, isFalse);
    expect(result.bytes, isEmpty);
    expect(result.error, isNotNull);
    expect(result.error, isNotEmpty);
  }

  /// Assert history entry is valid
  static void assertHistoryEntryValid(PatternHistoryEntry entry) {
    expect(entry.id, isNotEmpty);
    expect(entry.batchCode, isNotEmpty);
    expect(entry.algorithm, isNotEmpty);
    expect(entry.materialProfile, isNotEmpty);
    expect(entry.pattern, isNotEmpty);
    expect(entry.timestamp, isNotNull);
    expect(entry.pdfPath, isNotEmpty);
    expect(entry.pattern.every((row) => row.isNotEmpty), isTrue);
  }

  /// Assert pattern is valid (0s and 1s only)
  static void assertPatternValid(List<List<int>> pattern) {
    expect(pattern, isNotEmpty);
    for (final row in pattern) {
      expect(row, isNotEmpty);
      for (final cell in row) {
        expect(cell, inInclusiveRange(0, 1));
      }
    }
  }
}

/// Mock utilities for testing
class MockUtilities {
  /// Setup mock PDF service for successful generation
  static void setupMockPDFServiceSuccess(MockPDFService mockPdfService) {
    when(() => mockPdfService.generatePDF(any()))
        .thenAnswer((_) async => TestDataFactory.createTestPDFResult());
    when(() => mockPdfService.downloadOrSharePDF(any()))
        .thenAnswer((_) async => true);
  }

  /// Setup mock PDF service for failure
  static void setupMockPDFServiceFailure(MockPDFService mockPdfService, {String error = 'Test error'}) {
    final testResult = TestDataFactory.createTestPDFResult(
      success: false,
      error: error,
    );

    when(() => mockPdfService.generatePDF(any()))
        .thenAnswer((_) async => testResult);
    when(() => mockPdfService.downloadOrSharePDF(any()))
        .thenAnswer((_) async => false);
  }

  /// Setup mock history service
  static void setupMockHistoryService(MockHistoryService mockHistoryService, {
    List<PatternHistoryEntry>? entries,
    bool shouldThrow = false,
  }) {
    final testEntries = entries ?? [TestDataFactory.createTestHistoryEntry()];
    final testEntry = testEntries.first;
    final testFilter = TestDataFactory.createTestHistoryFilter();

    if (shouldThrow) {
      when(() => mockHistoryService.saveEntry(any()))
          .thenThrow(Exception('Test save error'));
      when(() => mockHistoryService.getAllEntries())
          .thenThrow(Exception('Test load error'));
      when(() => mockHistoryService.getEntry('test-id'))
          .thenThrow(Exception('Test get error'));
    } else {
      when(() => mockHistoryService.saveEntry(any()))
          .thenAnswer((_) async {});
      when(() => mockHistoryService.getAllEntries())
          .thenAnswer((_) async => testEntries);
      when(() => mockHistoryService.getFilteredEntries(testFilter))
          .thenAnswer((_) async => testEntries);
      when(() => mockHistoryService.getEntry('test-id'))
          .thenAnswer((_) async => testEntry);
      when(() => mockHistoryService.searchEntries('test'))
          .thenAnswer((_) async => testEntries);
      when(() => mockHistoryService.deleteEntry('test-id'))
          .thenAnswer((_) async {});
      when(() => mockHistoryService.clearAll())
          .thenAnswer((_) async {});
      when(() => mockHistoryService.getStatistics())
          .thenAnswer((_) async => {'total': testEntries.length});
    }
  }
}

/// Performance testing utilities
class PerformanceTestUtils {
  /// Measure execution time of a function
  static Future<Duration> measureExecutionTime(Future<void> Function() function) async {
    final stopwatch = Stopwatch()..start();
    await function();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Assert function executes within time limit
  static Future<void> assertExecutesWithin(
    Future<void> Function() function,
    Duration timeLimit, {
    String? description,
  }) async {
    final executionTime = await measureExecutionTime(function);
    expect(
      executionTime,
      lessThan(timeLimit),
      reason: description != null
        ? 'Function "$description" exceeded time limit: ${executionTime.inMilliseconds}ms > ${timeLimit.inMilliseconds}ms'
        : 'Function exceeded time limit: ${executionTime.inMilliseconds}ms > ${timeLimit.inMilliseconds}ms',
    );
  }
}

/// Platform testing utilities
class PlatformTestUtils {
  /// Create test data for different platforms
  static Map<String, dynamic> createPlatformSpecificTestData(String platform) {
    switch (platform.toLowerCase()) {
      case 'web':
        return {
          'platform': 'web',
          'storage': 'indexed_db',
          'pdf_download': 'browser',
        };
      case 'android':
        return {
          'platform': 'android',
          'storage': 'hive',
          'pdf_download': 'file_system',
        };
      case 'ios':
        return {
          'platform': 'ios',
          'storage': 'hive',
          'pdf_download': 'file_system',
        };
      default:
        return {
          'platform': 'unknown',
          'storage': 'default',
          'pdf_download': 'default',
        };
    }
  }

  /// Get platform-specific test expectations
  static Map<String, dynamic> getPlatformTestExpectations(String platform) {
    return {
      'web': {
        'pdf_download_supported': true,
        'storage_persistent': true,
        'file_system_access': false,
      },
      'android': {
        'pdf_download_supported': true,
        'storage_persistent': true,
        'file_system_access': true,
      },
      'ios': {
        'pdf_download_supported': true,
        'storage_persistent': true,
        'file_system_access': true,
      },
    }[platform.toLowerCase()] ?? {};
  }
}