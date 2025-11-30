import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'history_service.dart';

/// IndexedDB-based storage implementation for web platform
/// Note: This is a stub implementation to avoid analyzer errors
/// TODO: Implement proper IndexedDB storage when js_interop is stable
class IndexedDBStorageService implements HistoryService {
  @override
  Future<void> saveEntry(PatternHistoryEntry entry) async {
    if (!kIsWeb) {
      throw HistoryServiceException('IndexedDB storage service can only be used on web platform');
    }
    // Stub implementation - throw to indicate not implemented
    throw UnimplementedError('IndexedDB storage is not yet implemented');
  }

  @override
  Future<List<PatternHistoryEntry>> getAllEntries() async {
    if (!kIsWeb) {
      throw HistoryServiceException('IndexedDB storage service can only be used on web platform');
    }
    // Stub implementation - return empty list
    return [];
  }

  @override
  Future<List<PatternHistoryEntry>> getFilteredEntries(HistoryFilter filter) async {
    if (!kIsWeb) {
      throw HistoryServiceException('IndexedDB storage service can only be used on web platform');
    }
    // Stub implementation - return empty list
    return [];
  }

  @override
  Future<PatternHistoryEntry?> getEntry(String id) async {
    if (!kIsWeb) {
      throw HistoryServiceException('IndexedDB storage service can only be used on web platform');
    }
    // Stub implementation - return null
    return null;
  }

  @override
  Future<void> deleteEntry(String id) async {
    if (!kIsWeb) {
      throw HistoryServiceException('IndexedDB storage service can only be used on web platform');
    }
    // Stub implementation - do nothing
  }

  @override
  Future<void> clearAll() async {
    if (!kIsWeb) {
      throw HistoryServiceException('IndexedDB storage service can only be used on web platform');
    }
    // Stub implementation - do nothing
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    if (!kIsWeb) {
      throw HistoryServiceException('IndexedDB storage service can only be used on web platform');
    }
    // Stub implementation - return empty stats
    return {
      'totalEntries': 0,
      'algorithmCounts': <String, int>{},
      'materialCounts': <String, int>{},
      'oldestEntry': null,
      'newestEntry': null,
      'entriesThisMonth': 0,
      'entriesThisYear': 0,
    };
  }

  @override
  Future<List<PatternHistoryEntry>> searchEntries(String query) async {
    if (!kIsWeb) {
      throw HistoryServiceException('IndexedDB storage service can only be used on web platform');
    }
    // Stub implementation - return empty list
    return [];
  }
}