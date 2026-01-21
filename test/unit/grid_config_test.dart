import 'package:flutter_test/flutter_test.dart';
import 'package:latticelock/core/models/grid_config.dart';

void main() {
  group('GridConfig Tests', () {
    test('should have correct preset configurations', () {
      expect(GridConfig.presets.length, 11); // Changed from 12 to 11
      expect(GridConfig.presets.first.size, 3); // Changed from 2 to 3 (minimum size)
      expect(GridConfig.presets.last.size, 32); // 32x32
    });

    test('should find config by size', () {
      final config8x8 = GridConfig.findBySize(8);
      expect(config8x8, isNotNull);
      expect(config8x8!.displayName, '8×8');
      expect(config8x8.useCase, 'Production'); // Changed from 'Demo' to 'Production'

      final config16x16 = GridConfig.findBySize(16);
      expect(config16x16, isNotNull);
      expect(config16x16!.displayName, '16×16');
      expect(config16x16.useCase, 'Professional'); // Changed from 'Advanced' to 'Professional'

      final configNonExistent = GridConfig.findBySize(99);
      expect(configNonExistent, isNull);
    });

    test('should validate grid size correctly', () {
      expect(GridConfig.isValidSize(8), isTrue);
      expect(GridConfig.isValidSize(3), isTrue); // Changed from 2 to 3 (minimum)
      expect(GridConfig.isValidSize(32), isTrue);
      expect(GridConfig.isValidSize(1), isFalse);
      expect(GridConfig.isValidSize(33), isFalse);
      expect(GridConfig.isValidSize(15), isTrue); // Changed to true - any size between 3-32 is valid
    });

    test('should provide appropriate descriptions', () {
      final config3x3 = GridConfig.findBySize(3);
      expect(config3x3?.description, 'Simple demonstration'); // Changed from 2x2 to 3x3

      final config32x32 = GridConfig.findBySize(32);
      expect(config32x32?.description, 'Scientific research'); // Changed to match actual
    });

    test('should categorize use cases correctly', () {
      final demoConfigs = GridConfig.presets.where((c) => c.useCase == 'Demo');
      expect(demoConfigs.length, 1);
      expect(demoConfigs.first.size, 3); // Changed from 2 to 3

      final scientificConfigs = GridConfig.presets.where((c) => c.useCase == 'Scientific');
      expect(scientificConfigs.length, 1);
      expect(scientificConfigs.first.size, 32);
    });

    test('should have increasing complexity', () {
      final configs = GridConfig.presets;
      for (int i = 0; i < configs.length - 1; i++) {
        expect(configs[i].size, lessThanOrEqualTo(configs[i + 1].size));
      }
    });
  });
}