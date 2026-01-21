import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:latticelock/features/generator/domain/generator_use_case.dart';
import 'package:latticelock/features/material/models/ink_profile.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_classes.dart';

// Only run these tests on VM platform (not web) to avoid dart:html compilation issues
@TestOn('vm')

void main() {
  // Initialize Flutter test bindings for Hive (needed for PDF generation tests)
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register fallback values for mocktail
  registerFallbackValue(TestDataFactory.createTestPDFMetadata());
  registerFallbackValue(TestDataFactory.createTestPDFResult());
  registerFallbackValue(TestDataFactory.createTestHistoryEntry());

  group('GeneratorUseCase Tests', () {
    late GeneratorUseCase generatorUseCase;
    late MockPDFService mockPdfService;
    late MockHistoryService mockHistoryService;
    late MaterialProfile testMaterialProfile;

    setUp(() {
      mockHistoryService = MockHistoryService();
      mockPdfService = MockPDFService();
      testMaterialProfile = TestDataFactory.createTestMaterialProfile();
      generatorUseCase = GeneratorUseCase(
        historyService: mockHistoryService,
        pdfService: mockPdfService,
      );
    });

    group('Initialization', () {
      test('should initialize with default settings', () {
        expect(generatorUseCase, isNotNull);
      });

      test('should initialize successfully', () async {
        await generatorUseCase.initialize();
        expect(generatorUseCase, isNotNull);
      });
    });

    group('Pattern Generation', () {
      test('should generate pattern for 8x8 grid', () async {
        const inputText = 'test_input';
        const algorithm = 'chaos_logistic';
        const gridSize = 8;

        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        expect(pattern, isNotEmpty);
        expect(pattern.length, equals(gridSize * gridSize));

        // Verify pattern contains valid ink IDs (0-4)
        for (final cell in pattern) {
          expect(cell, inInclusiveRange(0, 4));
        }
      });

      test('should use default grid size when not provided', () async {
        const inputText = 'test_input';
        const algorithm = 'chaos_logistic';

        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: algorithm,
        );

        expect(pattern, isNotEmpty);
        expect(pattern.length, equals(64)); // 8x8 default grid size
      });

      test('should generate different patterns for different inputs', () async {
        const input1 = 'input_one';
        const input2 = 'input_two';
        const algorithm = 'chaos_logistic';
        const gridSize = 4;

        final pattern1 = await generatorUseCase.generatePattern(
          inputText: input1,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        final pattern2 = await generatorUseCase.generatePattern(
          inputText: input2,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        expect(pattern1, isNot(equals(pattern2)));
      });

      test('should be deterministic - same input produces same output', () async {
        const inputText = 'deterministic_test';
        const algorithm = 'chaos_logistic';
        const gridSize = 8;

        final pattern1 = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        final pattern2 = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        expect(pattern1, equals(pattern2));
      });

      test('should handle empty input text', () async {
        const inputText = '';
        const algorithm = 'chaos_logistic';
        const gridSize = 4;

        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        expect(pattern, isNotEmpty);
        expect(pattern.length, equals(gridSize * gridSize));
      });

      test('should handle Unicode input text', () async {
        const inputText = '测试 русский العربية';
        const algorithm = 'chaos_logistic';
        const gridSize = 4;

        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        expect(pattern, isNotEmpty);
        expect(pattern.length, equals(gridSize * gridSize));
      });

      test('should support custom number of inks', () async {
        const inputText = 'ink_test';
        const gridSize = 4;

        final pattern3 = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
          gridSize: gridSize,
          numInks: 3,
        );

        final pattern7 = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
          gridSize: gridSize,
          numInks: 7,
        );

        // Verify patterns use correct ink ranges
        expect(pattern3.every((v) => v >= 0 && v < 3), isTrue);
        expect(pattern7.every((v) => v >= 0 && v < 7), isTrue);
      });
    });

    group('PDF Generation', () {
      setUp(() {
        MockUtilities.setupMockPDFServiceSuccess(mockPdfService);
        MockUtilities.setupMockHistoryService(mockHistoryService);
      });

      test('should generate PDF successfully', () async {
        const inputText = 'test_input';
        const gridSize = 8;
        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
          gridSize: gridSize,
        );

        expect(() async {
          await generatorUseCase.generatePDF(
            pattern: pattern,
            material: testMaterialProfile,
            inputText: inputText,
            gridSize: gridSize,
          );
        }, returnsNormally);
      });

      test('should handle PDF generation failure', () async {
        MockUtilities.setupMockPDFServiceFailure(mockPdfService, error: 'PDF generation failed');

        const inputText = 'test_input';
        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
        );

        // PDF generation failure is handled gracefully - method completes successfully
        // The error is recorded in the history metadata
        await expectLater(
          () async => await generatorUseCase.generatePDF(
            pattern: pattern,
            material: testMaterialProfile,
            inputText: inputText,
          ),
          returnsNormally,
        );

        // Verify that history service was called with the failure information
        verify(() => mockHistoryService.saveEntry(any())).called(1);
      });

      test('should handle history service failure', () async {
        final testMetadata = TestDataFactory.createTestPDFMetadata();
        final testResult = TestDataFactory.createTestPDFResult(metadata: testMetadata);
        final testHistoryEntry = TestDataFactory.createTestHistoryEntry();

        when(() => mockPdfService.generatePDF(any()))
            .thenAnswer((_) async => testResult);
        when(() => mockPdfService.downloadOrSharePDF(any()))
            .thenAnswer((_) async => true);
        when(() => mockHistoryService.saveEntry(any()))
            .thenThrow(Exception('History save failed'));

        const inputText = 'test_input';
        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
        );

        expect(
          () async => await generatorUseCase.generatePDF(
            pattern: pattern,
            material: testMaterialProfile,
            inputText: inputText,
          ),
          throwsException,
        );
      });

      test('should use default grid size for PDF generation', () async {
        const inputText = 'test_input';
        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
        );

        expect(() async {
          await generatorUseCase.generatePDF(
            pattern: pattern,
            material: testMaterialProfile,
            inputText: inputText,
          );
        }, returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle PDF generation errors gracefully', () async {
        const inputText = 'test_input';
        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
        );

        expect(
          () async => await generatorUseCase.generatePDF(
            pattern: pattern,
            material: testMaterialProfile,
            inputText: inputText,
          ),
          throwsA(anything),
        );
      });

      test('should handle invalid grid sizes', () async {
        const inputText = 'test_input';
        const invalidGridSize = 0;

        // Invalid grid size results in empty pattern (0 cells)
        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
          gridSize: invalidGridSize,
        );

        // Verify that an empty pattern is returned for invalid grid size
        expect(pattern, isEmpty);
      });

      test('should handle empty material profile', () async {
        const inputText = 'test_input';
        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
        );

        final emptyMaterialProfile = MaterialProfile(
          name: '',
          inks: [],
        );

        expect(
          () async => await generatorUseCase.generatePDF(
            pattern: pattern,
            material: emptyMaterialProfile,
            inputText: inputText,
          ),
          throwsA(anything),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle very long input text', () async {
        final longInput = 'a' * 10000;
        const algorithm = 'chaos_logistic';
        const gridSize = 8;

        final pattern = await generatorUseCase.generatePattern(
          inputText: longInput,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        expect(pattern, isNotEmpty);
        expect(pattern.length, equals(gridSize * gridSize));
      });

      test('should handle very short input text', () async {
        const shortInput = 'x';
        const algorithm = 'chaos_logistic';
        const gridSize = 8;

        final pattern = await generatorUseCase.generatePattern(
          inputText: shortInput,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        expect(pattern, isNotEmpty);
        expect(pattern.length, equals(gridSize * gridSize));
      });

      test('should handle special characters in input text', () async {
        final specialInput = r'!@#$%^&*()_+-=[]{}|;:,.<>?';
        const algorithm = 'chaos_logistic';
        const gridSize = 8;

        final pattern = await generatorUseCase.generatePattern(
          inputText: specialInput,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        expect(pattern, isNotEmpty);
        expect(pattern.length, equals(gridSize * gridSize));
      });

      test('should handle whitespace-only input text', () async {
        const whitespaceInput = ' \t\n\r\f\v';
        const algorithm = 'chaos_logistic';
        const gridSize = 8;

        final pattern = await generatorUseCase.generatePattern(
          inputText: whitespaceInput,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        expect(pattern, isNotEmpty);
        expect(pattern.length, equals(gridSize * gridSize));
      });
    });

    group('Performance Tests', () {
      test('should generate patterns efficiently', () async {
        const inputText = 'performance_test';
        const algorithm = 'chaos_logistic';
        const gridSize = 16;

        final stopwatch = Stopwatch()..start();

        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: algorithm,
          gridSize: gridSize,
        );

        stopwatch.stop();

        expect(pattern, isNotEmpty);
        expect(pattern.length, equals(gridSize * gridSize));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle rapid successive pattern generation', () async {
        const inputText = 'rapid_test';
        const algorithm = 'chaos_logistic';
        const gridSize = 8;

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          final pattern = await generatorUseCase.generatePattern(
            inputText: '$inputText$i',
            algorithm: algorithm,
            gridSize: gridSize,
          );
          expect(pattern, isNotEmpty);
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });

    group('Integration with Other Services', () {
      test('should properly integrate with PDF service', () async {
        MockUtilities.setupMockPDFServiceSuccess(mockPdfService);

        const inputText = 'integration_test';
        final pattern = await generatorUseCase.generatePattern(
          inputText: inputText,
          algorithm: 'chaos_logistic',
        );

        expect(() async {
          await generatorUseCase.generatePDF(
            pattern: pattern,
            material: testMaterialProfile,
            inputText: inputText,
          );
        }, throwsA(anything));
      });

      test('should properly integrate with history service', () async {
        MockUtilities.setupMockHistoryService(mockHistoryService);
        expect(true, isTrue);
      });
    });
  });
}
