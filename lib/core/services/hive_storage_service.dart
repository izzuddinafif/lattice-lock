import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'history_service.dart';

/// Hive-based storage implementation for native platforms (mobile/desktop)
class HiveStorageService implements HistoryService {
  static const String _boxName = 'pattern_history';
  static const String _entriesKey = 'history_entries';

  late Box _box;
  bool _isInitialized = false;

  @override
  Future<void> saveEntry(PatternHistoryEntry entry) async {
    await _ensureInitialized();
    try {
      final entries = await getAllEntries();
      final existingIndex = entries.indexWhere((e) => e.id == entry.id);

      if (existingIndex >= 0) {
        entries[existingIndex] = entry;
      } else {
        entries.add(entry);
      }

      final jsonList = entries.map((e) => e.toJson()).toList();
      await _box.put(_entriesKey, jsonList);
    } catch (e) {
      throw HistoryServiceException('Failed to save entry: ${e.toString()}');
    }
  }

  @override
  Future<List<PatternHistoryEntry>> getAllEntries() async {
    await _ensureInitialized();
    try {
      final jsonList = _box.get(_entriesKey, defaultValue: <dynamic>[]);
      return (jsonList as List)
          .map((json) => PatternHistoryEntry.fromJson(Map<String, dynamic>.from(json)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      throw HistoryServiceException('Failed to load entries: ${e.toString()}');
    }
  }

  @override
  Future<List<PatternHistoryEntry>> getFilteredEntries(HistoryFilter filter) async {
    final allEntries = await getAllEntries();
    return allEntries.where(filter.matches).toList();
  }

  @override
  Future<PatternHistoryEntry?> getEntry(String id) async {
    final allEntries = await getAllEntries();
    try {
      return allEntries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _ensureInitialized();
    try {
      final entries = await getAllEntries();
      entries.removeWhere((entry) => entry.id == id);

      final jsonList = entries.map((e) => e.toJson()).toList();
      await _box.put(_entriesKey, jsonList);
    } catch (e) {
      throw HistoryServiceException('Failed to delete entry: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    await _ensureInitialized();
    try {
      await _box.delete(_entriesKey);
    } catch (e) {
      throw HistoryServiceException('Failed to clear entries: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    final entries = await getAllEntries();

    final algorithmCounts = <String, int>{};
    final materialCounts = <String, int>{};

    for (final entry in entries) {
      algorithmCounts[entry.algorithm] = (algorithmCounts[entry.algorithm] ?? 0) + 1;
      materialCounts[entry.materialProfile] = (materialCounts[entry.materialProfile] ?? 0) + 1;
    }

    return {
      'totalEntries': entries.length,
      'algorithmCounts': algorithmCounts,
      'materialCounts': materialCounts,
      'oldestEntry': entries.isNotEmpty ? entries.last.timestamp.toIso8601String() : null,
      'newestEntry': entries.isNotEmpty ? entries.first.timestamp.toIso8601String() : null,
      'entriesThisMonth': _getEntriesCountSince(entries, DateTime.now().subtract(const Duration(days: 30))),
      'entriesThisYear': _getEntriesCountSince(entries, DateTime.now().subtract(const Duration(days: 365))),
    };
  }

  @override
  Future<List<PatternHistoryEntry>> searchEntries(String query) async {
    final allEntries = await getAllEntries();
    final lowerQuery = query.toLowerCase();

    return allEntries.where((entry) {
      return entry.batchCode.toLowerCase().contains(lowerQuery) ||
             entry.algorithm.toLowerCase().contains(lowerQuery) ||
             entry.materialProfile.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      throw HistoryServiceException('Hive storage service cannot be used on web platform');
    }

    try {
      // Initialize Hive for native platforms
      if (!kIsWeb) {
        // Hive initialization is handled automatically by hive_flutter
        await Hive.initFlutter();
      }

      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final historyDir = '${appDir.path}/latticelock_history';
      await Directory(historyDir).create(recursive: true);

      // Open Hive box
      _box = await Hive.openBox(_boxName, path: historyDir);
      _isInitialized = true;
    } catch (e) {
      throw HistoryServiceException('Failed to initialize Hive storage: ${e.toString()}');
    }
  }

  int _getEntriesCountSince(List<PatternHistoryEntry> entries, DateTime since) {
    return entries.where((entry) => entry.timestamp.isAfter(since)).length;
  }

  /// Cleanup method to close Hive boxes
  Future<void> close() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }
}