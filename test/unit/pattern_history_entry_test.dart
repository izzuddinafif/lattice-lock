import 'package:flutter_test/flutter_test.dart';
import 'package:latticelock/core/models/pattern_history_entry.dart';

void main() {
  group('PatternHistoryEntry Tests', () {
    late DateTime testTimestamp;
    late List<List<int>> testPattern;

    setUp(() {
      testTimestamp = DateTime.now();
      testPattern = [
        [1, 2, 3],
        [4, 0, 1],
        [2, 3, 4]
      ];
    });

    test('should create entry with all required fields', () {
      final flattenedPattern = testPattern.expand((row) => row).toList();
      final entry = PatternHistoryEntry(
        id: 'test-123',
        inputText: 'BATCH-001',
        algorithm: 'chaos_logistic',
        gridSize: 3,
        material: 'standard',
        encryptedPattern: flattenedPattern,
        timestamp: testTimestamp,
      );

      expect(entry.id, 'test-123');
      expect(entry.encryptedPattern, equals(flattenedPattern));
      expect(entry.gridSize, 3);
      expect(entry.inputText, 'BATCH-001');
      expect(entry.algorithm, 'chaos_logistic');
      expect(entry.material, 'standard');
      expect(entry.timestamp, testTimestamp);
    });

    test('should create entry from Map', () {
      final flattenedPattern = testPattern.expand((row) => row).toList();
      final map = {
        'id': 'map-456',
        'inputText': 'BATCH-002',
        'gridSize': 3,
        'algorithm': 'chaos_tent',
        'material': 'advanced',
        'encryptedPattern': flattenedPattern,
        'timestamp': testTimestamp.toIso8601String(),
      };

      final entry = PatternHistoryEntry.fromMap(map);

      expect(entry.id, 'map-456');
      expect(entry.encryptedPattern, equals(flattenedPattern));
      expect(entry.gridSize, 3);
      expect(entry.inputText, 'BATCH-002');
      expect(entry.algorithm, 'chaos_tent');
      expect(entry.material, 'advanced');
      expect(entry.timestamp, testTimestamp);
    });

    test('should convert to Map', () {
      final flattenedPattern = testPattern.expand((row) => row).toList();
      final entry = PatternHistoryEntry(
        id: 'convert-789',
        inputText: 'BATCH-003',
        algorithm: 'chaos_arnolds_cat',
        gridSize: 3,
        material: 'premium',
        encryptedPattern: flattenedPattern,
        timestamp: testTimestamp,
      );

      final map = entry.toMap();

      expect(map['id'], 'convert-789');
      expect(map['encryptedPattern'], equals(flattenedPattern));
      expect(map['gridSize'], 3);
      expect(map['inputText'], 'BATCH-003');
      expect(map['algorithm'], 'chaos_arnolds_cat');
      expect(map['material'], 'premium');
      expect(map['timestamp'], testTimestamp.toIso8601String());
    });

    test('should handle equality correctly', () {
      final flattenedPattern = testPattern.expand((row) => row).toList();
      final entry1 = PatternHistoryEntry(
        id: 'same-id',
        inputText: 'BATCH-001',
        algorithm: 'chaos_logistic',
        gridSize: 3,
        material: 'standard',
        encryptedPattern: flattenedPattern,
        timestamp: testTimestamp,
      );

      final entry2 = PatternHistoryEntry(
        id: 'same-id',
        inputText: 'BATCH-001',
        algorithm: 'chaos_logistic',
        gridSize: 3,
        material: 'standard',
        encryptedPattern: flattenedPattern,
        timestamp: testTimestamp,
      );

      final entry3 = PatternHistoryEntry(
        id: 'different-id',
        inputText: 'BATCH-001',
        algorithm: 'chaos_logistic',
        gridSize: 3,
        material: 'standard',
        encryptedPattern: flattenedPattern,
        timestamp: testTimestamp,
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });

    test('should have correct hashCode', () {
      final flattenedPattern = testPattern.expand((row) => row).toList();
      final entry1 = PatternHistoryEntry(
        id: 'hash-test',
        inputText: 'BATCH-001',
        algorithm: 'chaos_logistic',
        gridSize: 3,
        material: 'standard',
        encryptedPattern: flattenedPattern,
        timestamp: testTimestamp,
      );

      final entry2 = PatternHistoryEntry(
        id: 'hash-test',
        inputText: 'BATCH-001',
        algorithm: 'chaos_logistic',
        gridSize: 3,
        material: 'standard',
        encryptedPattern: flattenedPattern,
        timestamp: testTimestamp,
      );

      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('should have correct toString', () {
      final flattenedPattern = testPattern.expand((row) => row).toList();
      final entry = PatternHistoryEntry(
        id: 'string-test',
        inputText: 'BATCH-001',
        algorithm: 'chaos_logistic',
        gridSize: 3,
        material: 'standard',
        encryptedPattern: flattenedPattern,
        timestamp: testTimestamp,
      );

      final string = entry.toString();
      expect(string, contains('PatternHistoryEntry'));
      expect(string, contains('id: string-test'));
      expect(string, contains('inputText: BATCH-001'));
      expect(string, contains('algorithm: chaos_logistic'));
    });

    test('should validate grid size matches pattern dimensions', () {
      final flattenedPattern = testPattern.expand((row) => row).toList();
      final entry = PatternHistoryEntry(
        id: 'validation-test',
        inputText: 'BATCH-001',
        algorithm: 'chaos_logistic',
        gridSize: 3,
        material: 'standard',
        encryptedPattern: flattenedPattern,
        timestamp: testTimestamp,
      );

      // For encryptedPattern, we validate the total length equals gridSize^2
      expect(entry.encryptedPattern.length, equals(entry.gridSize * entry.gridSize));
    });

    test('should handle empty pattern edge case', () {
      final entry = PatternHistoryEntry(
        id: 'empty-test',
        inputText: 'BATCH-EMPTY',
        algorithm: 'chaos_logistic',
        gridSize: 0,
        material: 'standard',
        encryptedPattern: [],
        timestamp: testTimestamp,
      );

      expect(entry.encryptedPattern, isEmpty);
      expect(entry.gridSize, 0);
    });
  });
}