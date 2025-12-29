import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/history_service.dart';
import '../../generator/domain/generator_use_case.dart' show globalHistoryService;

class HistoryState {
  final List<PatternHistoryEntry> entries;
  final List<PatternHistoryEntry> filteredEntries;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final HistoryFilter? activeFilter;

  const HistoryState({
    this.entries = const [],
    this.filteredEntries = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.activeFilter,
  });

  HistoryState copyWith({
    List<PatternHistoryEntry>? entries,
    List<PatternHistoryEntry>? filteredEntries,
    bool? isLoading,
    String? error,
    String? searchQuery,
    HistoryFilter? activeFilter,
  }) {
    return HistoryState(
      entries: entries ?? this.entries,
      filteredEntries: filteredEntries ?? this.filteredEntries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryService _historyService;

  HistoryNotifier(this._historyService) : super(const HistoryState()) {
    // Don't auto-load - let the screen call loadHistory() explicitly
    // This ensures fresh data when navigating to the history screen
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entries = await _historyService.getAllEntries();
      state = state.copyWith(
        entries: entries,
        filteredEntries: entries,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshHistory() async {
    await loadHistory();
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setFilter(HistoryFilter? filter) {
    state = state.copyWith(activeFilter: filter);
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      activeFilter: null,
    );
    _applyFilters();
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _historyService.deleteEntry(id);
      final updatedEntries = state.entries.where((entry) => entry.id != id).toList();
      state = state.copyWith(entries: updatedEntries);
      _applyFilters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await _historyService.clearAll();
      state = state.copyWith(
        entries: [],
        filteredEntries: [],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await _historyService.getStatistics();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  void _applyFilters() {
    var filtered = state.entries;

    // Apply search query filter
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered.where((entry) =>
          entry.batchCode.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          entry.algorithm.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          entry.materialProfile.toLowerCase().contains(state.searchQuery.toLowerCase())
      ).toList();
    }

    // Apply active filter
    if (state.activeFilter != null) {
      filtered = filtered.where(state.activeFilter!.matches).toList();
    }

    state = state.copyWith(filteredEntries: filtered);
  }
}

// Provider using the SAME global service instance used by generator
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(globalHistoryService);
});