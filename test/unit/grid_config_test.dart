import 'package:flutter_test/flutter_test.dart';
import 'package:latticelock/core/models/grid_config.dart';

void main() {
  group('GridConfig Tests', () {
    test('should have correct preset configurations', () {
      expect(GridConfig.presets.length, 12);
      expect(GridConfig.presets.first.size, 2); // 2x2
      expect(GridConfig.presets.last.size, 32); // 32x32
    });

    test('should find config by size', () {
      final config8x8 = GridConfig.findBySize(8);
      expect(config8x8, isNotNull);
      expect(config8x8!.displayName, '8×8');
      expect(config8x8.useCase, 'Demo');

      final config16x16 = GridConfig.findBySize(16);
      expect(config16x16, isNotNull);
      expect(config16x16!.displayName, '16×16');
      expect(config16x16.useCase, 'Advanced');

      final configNonExistent = GridConfig.findBySize(99);
      expect(configNonExistent, isNull);
    });

    test('should validate grid size correctly', () {
      expect(GridConfig.isValidSize(8), isTrue);
      expect(GridConfig.isValidSize(2), isTrue);
      expect(GridConfig.isValidSize(32), isTrue);
      expect(GridConfig.isValidSize(1), isFalse);
      expect(GridConfig.isValidSize(33), isFalse);
      expect(GridConfig.isValidSize(15), isFalse); // Not in predefined sizes
    });

    test('should provide appropriate descriptions', () {
      final config2x2 = GridConfig.findBySize(2);
      expect(config2x2?.description, 'Quick proof of concept');

      final config32x32 = GridConfig.findBySize(32);
      expect(config32x32?.description, 'Scientific research with high precision');
    });

    test('should categorize use cases correctly', () {
      final pocConfigs = GridConfig.presets.where((c) => c.useCase == 'PoC');
      expect(pocConfigs.length, 1);
      expect(pocConfigs.first.size, 2);

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