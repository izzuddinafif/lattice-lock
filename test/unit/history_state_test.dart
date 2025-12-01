import 'package:flutter_test/flutter_test.dart';
import 'package:latticelock/features/generator/logic/history_state.dart';
import 'package:latticelock/core/services/history_service.dart';

void main() {
  group('HistoryState Tests', () {
    late List<PatternHistoryEntry> sampleEntries;

    setUp(() {
      sampleEntries = [
        PatternHistoryEntry(
          id: '1',
          batchCode: 'BATCH-001',
          algorithm: 'chaos_logistic',
          materialProfile: 'standard',
          pattern: [
            [1, 2],
            [3, 4]
          ],
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          pdfPath: 'test1.pdf',
        ),
        PatternHistoryEntry(
          id: '2',
          batchCode: 'BATCH-002',
          algorithm: 'chaos_tent',
          materialProfile: 'advanced',
          pattern: [
            [0, 1, 2],
            [3, 4, 0],
            [1, 2, 3]
          ],
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          pdfPath: 'test2.pdf',
        ),
        PatternHistoryEntry(
          id: '3',
          batchCode: 'BATCH-003',
          algorithm: 'chaos_arnolds_cat',
          materialProfile: 'standard',
          pattern: [
            [1, 2, 3, 4],
            [0, 1, 2, 0],
            [3, 4, 0, 1],
            [2, 3, 4, 0]
          ],
          timestamp: DateTime.now(),
          pdfPath: 'test3.pdf',
        ),
      ];
    });

    test('should create initial state correctly', () {
      const state = HistoryState();

      expect(state.entries, isEmpty);
      expect(state.filteredEntries, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.searchQuery, isEmpty);
    });

    test('should create state with entries', () {
      final state = HistoryState(
        entries: sampleEntries,
        filteredEntries: sampleEntries,
        isLoading: true,
        searchQuery: 'test',
      );

      expect(state.entries, hasLength(3));
      expect(state.filteredEntries, hasLength(3)); // Should match entries when no filters applied
      expect(state.isLoading, isTrue);
      expect(state.searchQuery, 'test');
    });

    test('should copy with updated values', () {
      const originalState = HistoryState(isLoading: false);

      final newState = originalState.copyWith(
        isLoading: true,
        error: 'Test error',
        searchQuery: 'BATCH-001',
      );

      expect(newState.isLoading, isTrue);
      expect(newState.error, 'Test error');
      expect(newState.searchQuery, 'BATCH-001');
    });

    test('should filter by search query', () {
      final state = HistoryState(
        entries: sampleEntries,
        filteredEntries: sampleEntries,
        searchQuery: 'BATCH-001',
      );

      expect(state.filteredEntries, hasLength(1));
      expect(state.filteredEntries.first.batchCode, 'BATCH-001');
    });

    test('should filter by algorithm', () {
      final filter = HistoryFilter(algorithm: 'chaos_logistic');
      final state = HistoryState(
        entries: sampleEntries,
        filteredEntries: sampleEntries,
        activeFilter: filter,
      );

      expect(state.filteredEntries, hasLength(1));
      expect(state.filteredEntries.first.algorithm, 'chaos_logistic');
    });

    test('should filter by material', () {
      final filter = HistoryFilter(materialProfile: 'advanced');
      final state = HistoryState(
        entries: sampleEntries,
        filteredEntries: sampleEntries,
        activeFilter: filter,
      );

      expect(state.filteredEntries, hasLength(1));
      expect(state.filteredEntries.first.materialProfile, 'advanced');
    });

    test('should apply multiple filters', () {
      final filter = HistoryFilter(
        algorithm: 'chaos_logistic',
        materialProfile: 'standard',
      );
      final state = HistoryState(
        entries: sampleEntries,
        filteredEntries: sampleEntries,
        searchQuery: 'BATCH-001',
        activeFilter: filter,
      );

      expect(state.filteredEntries, hasLength(1));
      expect(state.filteredEntries.first.batchCode, 'BATCH-001');
      expect(state.filteredEntries.first.algorithm, 'chaos_logistic');
      expect(state.filteredEntries.first.materialProfile, 'standard');
    });

    test('should handle no filter matches', () {
      final state = HistoryState(
        entries: sampleEntries,
        filteredEntries: sampleEntries,
        searchQuery: 'NONEXISTENT',
      );

      expect(state.filteredEntries, isEmpty);
    });

    test('should reset filters when query is empty', () {
      final state = HistoryState(
        entries: sampleEntries,
        filteredEntries: sampleEntries,
        searchQuery: '',
        activeFilter: null,
      );

      expect(state.filteredEntries, hasLength(3)); // Should show all entries
    });

    test('should have correct toString', () {
      const state = HistoryState(
        isLoading: false,
        searchQuery: 'test',
      );

      final string = state.toString();
      expect(string, contains('HistoryState'));
      expect(string, contains('isLoading: false'));
      expect(string, contains('searchQuery: test'));
    });

    test('should maintain immutability', () {
      const originalState = HistoryState(entries: []);

      final modifiedState = originalState.copyWith(
        entries: sampleEntries,
        isLoading: true,
      );

      expect(originalState.entries, isEmpty); // Original should remain unchanged
      expect(modifiedState.entries, hasLength(3)); // Modified should have new entries
      expect(modifiedState.isLoading, isTrue);
    });
  });
}