import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latticelock/features/material/models/custom_ink_profile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Widget test helper functions
class WidgetTestHelpers {
  static bool _isInitialized = false;

  /// Initialize Hive for widget tests
  static Future<void> initHive() async {
    if (_isInitialized) return;

    // Use in-memory database for tests
    Hive.init('./test_hive');

    // Register adapters
    Hive.registerAdapter(CustomInkDefinitionAdapter());
    Hive.registerAdapter(CustomMaterialProfileAdapter());

    _isInitialized = true;
  }

  /// Clean up Hive after tests
  static Future<void> cleanupHive() async {
    if (_isInitialized) {
      await Hive.close();
      _isInitialized = false;
    }
  }

  /// Setup all test dependencies
  static Future<void> setupTestEnvironment() async {
    await initHive();
    TestWidgetsFlutterBinding.ensureInitialized();
  }
}
