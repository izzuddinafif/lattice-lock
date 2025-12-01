import 'package:flutter_test/flutter_test.dart';
import 'package:latticelock/features/generator/logic/generator_state.dart';
import 'package:latticelock/core/models/grid_config.dart';
import 'package:latticelock/features/material/models/ink_profile.dart';

void main() {
  group('GeneratorState Tests', () {
    test('should create initial state correctly', () {
      final state = GeneratorState(
        inputText: '',
        selectedAlgorithm: 'chaos_logistic',
        selectedMaterial: MaterialProfile.standardSet,
        selectedGridConfig: const GridConfig(
        size: 8,
        displayName: '8×8',
        description: 'Standard grid',
        useCase: 'Standard',
      ),
        encryptedPattern: [],
        isGenerating: false,
      );

      expect(state.selectedGridConfig.size, 8);
      expect(state.encryptedPattern, isEmpty);
      expect(state.inputText, isEmpty);
      expect(state.isGenerating, isFalse);
      expect(state.error, isNull);
    });

    test('should create state with custom values', () {
      final gridConfig = GridConfig.findBySize(2)!;

      final flattenedPattern = [1, 2, 3, 4];

      final state = GeneratorState(
        inputText: 'TEST-001',
        selectedAlgorithm: 'chaos_logistic',
        selectedMaterial: MaterialProfile.standardSet,
        selectedGridConfig: gridConfig,
        encryptedPattern: flattenedPattern,
        isGenerating: true,
        error: 'Test error',
      );

      expect(state.selectedGridConfig.size, 2);
      expect(state.encryptedPattern, equals(flattenedPattern));
      expect(state.inputText, 'TEST-001');
      expect(state.isGenerating, isTrue);
      expect(state.error, 'Test error');
      expect(state.selectedGridConfig, gridConfig);
    });

    test('should copy with updated values', () {
      final originalState = GeneratorState(
        inputText: 'BATCH-001',
        selectedAlgorithm: 'chaos_logistic',
        selectedMaterial: MaterialProfile.standardSet,
        selectedGridConfig: const GridConfig(
          size: 4,
          displayName: '4×4',
          description: 'Small grid',
          useCase: 'Small',
        ),
        encryptedPattern: [],
        isGenerating: false,
      );

      final newState = originalState.copyWith(
        selectedGridConfig: const GridConfig(
          size: 8,
          displayName: '8×8',
          description: 'Medium grid',
          useCase: 'Medium',
        ),
        isGenerating: true,
      );

      expect(newState.selectedGridConfig.size, 8);
      expect(newState.inputText, 'BATCH-001'); // Should remain unchanged
      expect(newState.isGenerating, isTrue);
    });

    test('should have correct toString', () {
      final state = GeneratorState(
        inputText: 'test',
        selectedAlgorithm: 'chaos_logistic',
        selectedMaterial: MaterialProfile.standardSet,
        selectedGridConfig: const GridConfig(
          size: 16,
          displayName: '16×16',
          description: 'Large grid',
          useCase: 'Large',
        ),
        encryptedPattern: [],
        isGenerating: false,
      );

      final string = state.toString();
      expect(string, contains('GeneratorState'));
      expect(string, contains('selectedGridConfig.size: 16'));
      expect(string, contains('isGenerating: false'));
    });

    test('should maintain immutability', () {
      final originalState = GeneratorState(
        inputText: '',
        selectedAlgorithm: 'chaos_logistic',
        selectedMaterial: MaterialProfile.standardSet,
        selectedGridConfig: const GridConfig(
          size: 8,
          displayName: '8×8',
          description: 'Standard grid',
          useCase: 'Standard',
        ),
        encryptedPattern: [],
        isGenerating: false,
      );

      final modifiedState = originalState.copyWith(
        selectedGridConfig: const GridConfig(
          size: 16,
          displayName: '16×16',
          description: 'Large grid',
          useCase: 'Large',
        ),
      );

      expect(originalState.selectedGridConfig.size, 8); // Original should remain unchanged
      expect(modifiedState.selectedGridConfig.size, 16); // Modified should have new value
    });
  });
}