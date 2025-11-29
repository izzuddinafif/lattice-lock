import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'features/generator/presentation/generator_screen.dart';
import 'core/services/crypto_integration_test.dart';
import 'core/services/native_crypto_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize crypto services
  if (kDebugMode) {
    try {
      await NativeCryptoService.initialize();
      
      // Run integration tests in debug mode
      final testResults = await CryptoIntegrationTest.runAllTests();
      CryptoIntegrationTest.printTestResults(testResults);
    } catch (e) {
      debugPrint('Failed to initialize crypto services: $e');
    }
  }
  
  runApp(
    const ProviderScope(
      child: LatticeLockApp(),
    ),
  );
}

class LatticeLockApp extends StatelessWidget {
  const LatticeLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LatticeLock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const GeneratorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}