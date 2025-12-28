import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'history_service.dart';

/// Hive-based storage implementation for both web and native platforms
/// Uses IndexedDB on web, local file storage on mobile/desktop
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

      if (kDebugMode) {
        print('💾 [HIVE STORAGE] Saved entry: ${entry.batchCode} (total: ${entries.length} entries)');
        if (kIsWeb) {
          print('💾 [HIVE STORAGE] Data persisted to IndexedDB');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HIVE STORAGE] Failed to save entry: $e');
      }
      throw HistoryServiceException('Failed to save entry: ${e.toString()}');
    }
  }

  @override
  Future<List<PatternHistoryEntry>> getAllEntries() async {
    await _ensureInitialized();
    try {
      final jsonList = _box.get(_entriesKey, defaultValue: <dynamic>[]);
      final entries = (jsonList as List)
          .map((json) => PatternHistoryEntry.fromJson(Map<String, dynamic>.from(json)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (kDebugMode) {
        print('📖 [HIVE STORAGE] Loaded ${entries.length} entries from ${kIsWeb ? "IndexedDB" : "Hive box"}');
      }

      return entries;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HIVE STORAGE] Failed to load entries: $e');
      }
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

    try {
      if (kDebugMode) {
        print('💾 [HIVE STORAGE] Initializing on ${kIsWeb ? "WEB" : "NATIVE"} platform');
      }

      // Hive initialization is already handled in main.dart for both platforms
      // Hive.initFlutter() supports IndexedDB on web

      if (kIsWeb) {
        // On web, Hive stores data in browser's IndexedDB automatically
        _box = await Hive.openBox(_boxName);
      } else {
        // On native platforms, use custom directory for better organization
        final appDir = await getApplicationDocumentsDirectory();
        final historyDir = '${appDir.path}/latticelock_history';
        await Directory(historyDir).create(recursive: true);
        _box = await Hive.openBox(_boxName, path: historyDir);
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ [HIVE STORAGE] Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [HIVE STORAGE] Initialization failed: $e');
      }
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