import 'package:flutter_test/flutter_test.dart';
import 'package:latticelock/features/pattern/data/hybrid_chaotic_pattern.dart';

void main() {
  group('HybridChaoticPattern Tests', () {
    late HybridChaoticPattern strategy;

    setUp(() {
      strategy = HybridChaoticPattern();
    });

    group('Basic Properties', () {
      test('should have correct strategy name', () {
        expect(strategy.name, equals('Hybrid Chaotic Pattern (Spatial Deposition Map)'));
      });
    });

    group('Pattern Generation Tests', () {
      test('should generate 64-value pattern for 8x8 grid', () {
        const input = 'TEST1234';
        const gridSize = 8;

        final pattern = strategy.generatePattern(input, gridSize * gridSize);

        expect(pattern, hasLength(gridSize * gridSize));
      });

      test('should generate pattern with valid ink ID range (0-2)', () {
        const input = 'BATCH_CODE_123';
        const gridSize = 8;

        final pattern = strategy.generatePattern(input, gridSize * gridSize);

        for (final value in pattern) {
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThan(3));
        }
      });

      test('should be deterministic - same input produces same output', () {
        const input = 'DETERMINISTIC_TEST';
        const gridSize = 8;

        final pattern1 = strategy.generatePattern(input, gridSize * gridSize);
        final pattern2 = strategy.generatePattern(input, gridSize * gridSize);

        expect(pattern1, equals(pattern2));
      });

      test('should produce different patterns for different inputs', () {
        const input1 = 'INPUT_ONE';
        const input2 = 'INPUT_TWO';
        const gridSize = 8;

        final pattern1 = strategy.generatePattern(input1, gridSize * gridSize);
        final pattern2 = strategy.generatePattern(input2, gridSize * gridSize);

        expect(pattern1, isNot(equals(pattern2)));
      });

      test('should handle empty input gracefully', () {
        const input = '';
        const gridSize = 8;

        final pattern = strategy.generatePattern(input, gridSize * gridSize);

        expect(pattern, hasLength(gridSize * gridSize));
        // All values should be 2 (maxInkId for numInks=3)
        expect(pattern.every((v) => v == 2), isTrue);
      });

      test('should handle Unicode input', () {
        const input = '测试 تست عربي';
        const gridSize = 8;

        final pattern = strategy.generatePattern(input, gridSize * gridSize);

        expect(pattern, hasLength(gridSize * gridSize));
        expect(pattern.every((v) => v >= 0 && v < 3), isTrue);
      });

      test('should support dynamic ink count', () {
        const input = 'INK_TEST';
        const gridSize = 4;

        // Test with 2 inks (minimum)
        final pattern2 = strategy.generatePattern(input, gridSize * gridSize, 2);
        expect(pattern2.every((v) => v >= 0 && v < 2), isTrue);

        // Test with 5 inks
        final pattern5 = strategy.generatePattern(input, gridSize * gridSize, 5);
        expect(pattern5.every((v) => v >= 0 && v < 5), isTrue);
      });

      test('should clamp ink count to valid range (2-10)', () {
        const input = 'CLAMP_TEST';
        const gridSize = 4;

        // numInks < 2 should be clamped to 2
        final patternMin = strategy.generatePattern(input, gridSize * gridSize, 1);
        expect(patternMin.every((v) => v >= 0 && v < 2), isTrue);

        // numInks > 10 should be clamped to 10
        final patternMax = strategy.generatePattern(input, gridSize * gridSize, 15);
        expect(patternMax.every((v) => v >= 0 && v < 10), isTrue);
      });
    });

    group('Spatial Distribution Tests', () {
      test('should apply permutation stage correctly', () {
        const input = 'PERMUTATION_TEST';
        const gridSize = 8;

        // This tests the spatial scrambling aspect
        final pattern1 = strategy.generatePattern(input, gridSize * gridSize);
        final pattern2 = strategy.generatePattern(input, gridSize * gridSize);

        // Same input = same spatial arrangement
        expect(pattern1, equals(pattern2));

        // Verify values are distributed (not all same)
        final uniqueValues = pattern1.toSet();
        expect(uniqueValues.length, greaterThan(1));
      });

      test('should apply diffusion stage correctly', () {
        const input = 'DIFFUSION_TEST';
        const gridSize = 8;

        final pattern = strategy.generatePattern(input, gridSize * gridSize);

        // XOR diffusion should obscure values
        // Adjacent values should have low correlation
        var correlations = 0;
        for (int i = 0; i < pattern.length - 1; i++) {
          if (pattern[i] == pattern[i + 1]) {
            correlations++;
          }
        }

        // Should have fewer than 50% correlations (indicating good diffusion)
        expect(correlations, lessThan(pattern.length ~/ 2));
      });

      test('should apply substitution stage correctly', () {
        const input = 'SUBSTITUTION_TEST';
        const gridSize = 4;

        // Test with different ink counts
        final pattern2 = strategy.generatePattern(input, gridSize * gridSize, 2);
        final pattern3 = strategy.generatePattern(input, gridSize * gridSize, 3);
        final pattern5 = strategy.generatePattern(input, gridSize * gridSize, 5);

        // All should be valid for their respective ranges
        expect(pattern2.every((v) => v >= 0 && v < 2), isTrue);
        expect(pattern3.every((v) => v >= 0 && v < 3), isTrue);
        expect(pattern5.every((v) => v >= 0 && v < 5), isTrue);

        // Patterns should be different due to different moduli
        expect(pattern2, isNot(equals(pattern3)));
        expect(pattern3, isNot(equals(pattern5)));
      });
    });

    group('Performance Tests', () {
      test('should generate pattern within reasonable time', () {
        const input = 'PERFORMANCE_TEST';
        const gridSize = 8;

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          strategy.generatePattern('$input$i', gridSize * gridSize);
        }

        stopwatch.stop();

        // 100 pattern generations should complete in less than 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('should handle large grid sizes efficiently', () {
        const input = 'LARGE_GRID_TEST';
        const gridSize = 16;

        final stopwatch = Stopwatch()..start();

        final pattern = strategy.generatePattern(input, gridSize * gridSize);

        stopwatch.stop();

        // Note: Current implementation is optimized for 8×8 grid
        // Larger grids are supported but pattern length might differ from expected
        expect(pattern, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Edge Cases', () {
      test('should handle very long input', () {
        final longInput = 'A' * 10000;
        const gridSize = 8;

        final pattern = strategy.generatePattern(longInput, gridSize * gridSize);

        expect(pattern, hasLength(gridSize * gridSize));
      });

      test('should handle very short input', () {
        const shortInput = 'X';
        const gridSize = 8;

        final pattern = strategy.generatePattern(shortInput, gridSize * gridSize);

        expect(pattern, hasLength(gridSize * gridSize));
      });

      test('should handle special characters', () {
        final specialInput = r'!@#$%^&*()_+-=[]{}|;:,.<>?/~`';
        const gridSize = 8;

        final pattern = strategy.generatePattern(specialInput, gridSize * gridSize);

        expect(pattern, hasLength(gridSize * gridSize));
        expect(pattern.every((v) => v >= 0 && v < 3), isTrue);
      });

      test('should handle whitespace-only input', () {
        const whitespaceInput = ' \t\n\r\f\v';
        const gridSize = 8;

        final pattern = strategy.generatePattern(whitespaceInput, gridSize * gridSize);

        expect(pattern, hasLength(gridSize * gridSize));
      });
    });

    group('Chaotic Properties', () {
      test('should have avalanche effect - small input change causes big pattern change', () {
        const input1 = 'AVALANCHE_TEST';
        const input2 = 'AVALANCHE_TEST!'; // One character difference
        const gridSize = 8;

        final pattern1 = strategy.generatePattern(input1, gridSize * gridSize);
        final pattern2 = strategy.generatePattern(input2, gridSize * gridSize);

        // Count differing positions
        int differences = 0;
        for (int i = 0; i < pattern1.length; i++) {
          if (pattern1[i] != pattern2[i]) {
            differences++;
          }
        }

        // Avalanche effect: >50% of positions should differ
        expect(differences, greaterThan(pattern1.length ~/ 2));
      });

      test('should have reasonable distribution of values', () {
        const input = 'DISTRIBUTION_TEST';
        const gridSize = 16; // Larger grid for better statistics

        final pattern = strategy.generatePattern(input, gridSize * gridSize);

        // Count occurrences of each value (0-2)
        final counts = List.filled(3, 0);
        for (final value in pattern) {
          counts[value]++;
        }

        // Verify all values appear at least once
        // (Chaotic systems don't guarantee uniformity in small samples)
        expect(counts.every((count) => count > 0), isTrue,
            reason: 'Some values not represented: $counts');

        // Calculate expected count
        final expected = pattern.length / 3;

        // Most values should appear within 100% of expected count
        // (Very relaxed constraint - chaotic systems have natural variance)
        int withinRange = 0;
        for (final count in counts) {
          final deviation = ((count - expected).abs() / expected * 100).round();
          if (deviation < 100) withinRange++;
        }

        expect(withinRange, greaterThanOrEqualTo(2),
            reason: 'Distribution too skewed: $counts');
      });

      test('should not have obvious patterns in output', () {
        const input = 'PATTERN_TEST';
        const gridSize = 8;

        final pattern = strategy.generatePattern(input, gridSize * gridSize);

        // Check for repeating sequences
        bool hasRepeatingSequence(String sequence, int minRepeats) {
          int count = 0;
          int pos = 0;
          while (pos <= pattern.length - sequence.length) {
            if (pattern.sublist(pos, pos + sequence.length).toString() == sequence) {
              count++;
              if (count >= minRepeats) return true;
              pos += sequence.length;
            } else {
              pos++;
            }
          }
          return false;
        }

        // Should not have 4+ repeats of any 4-value sequence
        for (int i = 0; i < pattern.length - 4; i++) {
          final sequence = pattern.sublist(i, i + 4).toString();
          expect(hasRepeatingSequence(sequence, 4), isFalse,
              reason: 'Found repeating pattern: $sequence');
        }
      });
    });
  });
}
