import 'dart:async';
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
    // Treat empty strings the same as null (no filtering applied)
    if (batchCode != null && batchCode!.isNotEmpty && !entry.batchCode.toLowerCase().contains(batchCode!.toLowerCase())) {
      return false;
    }
    if (algorithm != null && algorithm!.isNotEmpty && entry.algorithm != algorithm) {
      return false;
    }
    if (materialProfile != null && materialProfile!.isNotEmpty && entry.materialProfile != materialProfile) {
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
    // Use Hive for both web and mobile - Hive supports IndexedDB on web
    return HiveStorageService();
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