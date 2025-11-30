import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform detection utility for cross-platform functionality
class PlatformDetector {
  static bool get isWeb => kIsWeb;

  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);

  static bool get isDesktop => !kIsWeb && (isWindows || isMacOS || isLinux);

  static bool get isAndroid => false; // Can't detect without dart:io on web
  static bool get isIOS => false;     // Can't detect without dart:io on web
  static bool get isWindows => false; // Can't detect without dart:io on web
  static bool get isMacOS => false;   // Can't detect without dart:io on web
  static bool get isLinux => false;   // Can't detect without dart:io on web

  /// Get platform-specific download behavior
  static DownloadBehavior get downloadBehavior {
    if (isWeb) return DownloadBehavior.browserDownload;
    if (isMobile) return DownloadBehavior.shareMenu;
    return DownloadBehavior.fileSave;
  }

  /// Get platform-specific storage type
  static StorageType get storageType {
    if (isWeb) return StorageType.indexedDB;
    return StorageType.hive;
  }
}

enum DownloadBehavior {
  browserDownload,
  shareMenu,
  fileSave,
}

enum StorageType {
  indexedDB,
  hive,
  secureStorage,
}