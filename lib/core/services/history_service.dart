import 'dart:async';
import '../utils/platform_detector.dart';
import 'hive_storage_service.dart';

/// Model for stored pattern history entry
class PatternHistoryEntry {
  final String id;
  final String batchCode;
  final String algorithm;
  final String materialProfile;
  final List<List<int>> pattern;
  final DateTime timestamp;
  final String pdfPath;
  final Map<String, dynamic> metadata;

  PatternHistoryEntry({
    required this.id,
    required this.batchCode,
    required this.algorithm,
    required this.materialProfile,
    required this.pattern,
    required this.timestamp,
    required this.pdfPath,
    this.metadata = const {},
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchCode': batchCode,
      'algorithm': algorithm,
      'materialProfile': materialProfile,
      'pattern': pattern,
      'timestamp': timestamp.toIso8601String(),
      'pdfPath': pdfPath,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory PatternHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PatternHistoryEntry(
      id: json['id'],
      batchCode: json['batchCode'],
      algorithm: json['algorithm'],
      materialProfile: json['materialProfile'],
      pattern: List<List<int>>.from(json['pattern'].map((row) => List<int>.from(row))),
      timestamp: DateTime.parse(json['timestamp']),
      pdfPath: json['pdfPath'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Search filters for history entries
class HistoryFilter {
  final String? batchCode;
  final String? algorithm;
  final String? materialProfile;
  final DateTime? startDate;
  final DateTime? endDate;

  const HistoryFilter({
    this.batchCode,
    this.algorithm,
    this.materialProfile,
    this.startDate,
    this.endDate,
  });

  bool matches(PatternHistoryEntry entry) {
    if (batchCode != null && !entry.batchCode.toLowerCase().contains(batchCode!.toLowerCase())) {
      return false;
    }
    if (algorithm != null && entry.algorithm != algorithm) {
      return false;
    }
    if (materialProfile != null && entry.materialProfile != materialProfile) {
      return false;
    }
    if (startDate != null && entry.timestamp.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && entry.timestamp.isAfter(endDate!)) {
      return false;
    }
    return true;
  }
}

/// Abstract history service interface for cross-platform storage
abstract class HistoryService {
  /// Save a pattern history entry
  Future<void> saveEntry(PatternHistoryEntry entry);

  /// Get all history entries
  Future<List<PatternHistoryEntry>> getAllEntries();

  /// Get entries matching filter
  Future<List<PatternHistoryEntry>> getFilteredEntries(HistoryFilter filter);

  /// Get entry by ID
  Future<PatternHistoryEntry?> getEntry(String id);

  /// Delete entry by ID
  Future<void> deleteEntry(String id);

  /// Clear all entries
  Future<void> clearAll();

  /// Get statistics about stored entries
  Future<Map<String, dynamic>> getStatistics();

  /// Search entries by text query
  Future<List<PatternHistoryEntry>> searchEntries(String query);

  /// Get platform-specific implementation
  factory HistoryService.create() {
    if (PlatformDetector.isWeb) {
      // Use in-memory storage for web until IndexedDB is implemented
      return _InMemoryHistoryService();
    } else {
      return HiveStorageService();
    }
  }
}

/// In-memory history service for web (global singleton instance)
class _InMemoryHistoryService implements HistoryService {
  // Static list that persists across ALL instances
  static final List<PatternHistoryEntry> _globalEntries = [];

  // Global singleton instance - created once and reused
  static final _InMemoryHistoryService _instance = _InMemoryHistoryService._internal();

  // Private constructor
  _InMemoryHistoryService._internal();

  // Factory that always returns the same global instance
  factory _InMemoryHistoryService() => _instance;

  // Access the global entries list
  List<PatternHistoryEntry> get _entries => _globalEntries;

  @override
  Future<void> saveEntry(PatternHistoryEntry entry) async {
    _entries.removeWhere((e) => e.id == entry.id);
    _entries.add(entry);
    print('📝 History saved: ${entry.batchCode} (total: ${_entries.length} entries)');
  }

  @override
  Future<List<PatternHistoryEntry>> getAllEntries() async {
    print('📖 Loading history: ${_entries.length} entries (instance: ${identityHashCode(this)})');
    return List.from(_entries.reversed);
  }

  @override
  Future<List<PatternHistoryEntry>> getFilteredEntries(HistoryFilter filter) async {
    return _entries.where(filter.matches).toList().reversed.toList();
  }

  @override
  Future<PatternHistoryEntry?> getEntry(String id) async {
    try {
      return _entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<void> clearAll() async {
    _entries.clear();
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    return {
      'totalEntries': _entries.length,
      'algorithms': _entries.map((e) => e.algorithm).toSet().length,
      'materialProfiles': _entries.map((e) => e.materialProfile).toSet().length,
      'latestEntry': _entries.isNotEmpty ? _entries.last.timestamp.toIso8601String() : null,
    };
  }

  @override
  Future<List<PatternHistoryEntry>> searchEntries(String query) async {
    final lowercaseQuery = query.toLowerCase();
    return _entries.where((entry) {
      return entry.batchCode.toLowerCase().contains(lowercaseQuery) ||
             entry.algorithm.toLowerCase().contains(lowercaseQuery) ||
             entry.materialProfile.toLowerCase().contains(lowercaseQuery);
    }).toList().reversed.toList();
  }
}

/// Exception thrown when history service operations fail
class HistoryServiceException implements Exception {
  final String message;
  final String? code;

  const HistoryServiceException(this.message, [this.code]);

  @override
  String toString() => 'HistoryServiceException: $message${code != null ? ' (code: $code)' : ''}';
}