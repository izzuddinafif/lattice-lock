import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latticelock/features/generator/presentation/generator_screen.dart';

void main() {
  group('GeneratorScreen Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createWidgetUnderTest() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: GeneratorScreen(),
        ),
      );
    }

    testWidgets('should display all initial UI elements', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify main elements are present
      expect(find.text('LatticeLock Pattern Generator'), findsOneWidget);
      expect(find.text('Grid Size'), findsOneWidget);
      expect(find.text('Batch Code'), findsOneWidget);
      expect(find.text('Algorithm'), findsOneWidget);
      expect(find.text('Material Profile'), findsOneWidget);
      expect(find.text('Generate Pattern'), findsOneWidget);
    });

    testWidgets('should display grid size dropdown with correct default', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find and verify grid size dropdown
      final gridSizeDropdown = find.byKey(const Key('grid_size_dropdown'));
      expect(gridSizeDropdown, findsOneWidget);

      // Should show default 8×8
      expect(find.text('8×8 Demo'), findsOneWidget);
    });

    testWidgets('should change grid size when dropdown is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap the grid size dropdown
      await tester.tap(find.byKey(const Key('grid_size_dropdown')));
      await tester.pumpAndSettle();

      // Verify dropdown items are present
      expect(find.text('2×2 PoC'), findsOneWidget);
      expect(find.text('16×16 Advanced'), findsOneWidget);
      expect(find.text('32×32 Scientific'), findsOneWidget);

      // Select 4×4 option
      await tester.tap(find.text('4×4 Testing'));
      await tester.pumpAndSettle();

      // Verify selection changed
      expect(find.text('4×4 Testing'), findsOneWidget);
    });

    testWidgets('should update batch code when typed', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find batch code text field
      final batchCodeField = find.byKey(const Key('batch_code_field'));
      expect(batchCodeField, findsOneWidget);

      // Enter batch code
      await tester.enterText(batchCodeField, 'TEST-001');
      await tester.pump();

      // Verify text was entered
      expect(find.text('TEST-001'), findsOneWidget);
    });

    testWidgets('should show algorithm dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find algorithm dropdown
      final algorithmDropdown = find.byKey(const Key('algorithm_dropdown'));
      expect(algorithmDropdown, findsOneWidget);

      // Tap to show options
      await tester.tap(algorithmDropdown);
      await tester.pumpAndSettle();

      // Verify algorithms are present
      expect(find.text('Logistic Map'), findsOneWidget);
      expect(find.text('Tent Map'), findsOneWidget);
      expect(find.text('Arnold\'s Cat Map'), findsOneWidget);
    });

    testWidgets('should show material profile options', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find material profile dropdown
      final materialDropdown = find.byKey(const Key('material_dropdown'));
      expect(materialDropdown, findsOneWidget);

      // Tap to show options
      await tester.tap(materialDropdown);
      await tester.pumpAndSettle();

      // Verify material profiles are present
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('should show ink type selector', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify ink type buttons are present
      expect(find.text('75R (Red)'), findsOneWidget);
      expect(find.text('75P (Dark)'), findsOneWidget);
      expect(find.text('55R (Orange)'), findsOneWidget);
      expect(find.text('55P (Yellow)'), findsOneWidget);
      expect(find.text('35M (Green)'), findsOneWidget);
    });

    testWidgets('should select ink types when buttons are tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find 75R button
      final inkButton = find.text('75R (Red)');
      expect(inkButton, findsOneWidget);

      // Tap to select
      await tester.tap(inkButton);
      await tester.pump();

      // Button should be selected (this would require checking the button state)
      // For now, just verify it's still present and tappable
      expect(inkButton, findsOneWidget);
    });

    testWidgets('should show grid visualization area', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify grid area is present
      final gridArea = find.byKey(const Key('grid_visualization'));
      expect(gridArea, findsOneWidget);

      // Should show placeholder text initially
      expect(find.text('Pattern will appear here'), findsOneWidget);
    });

    testWidgets('should handle generate pattern button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find generate button
      final generateButton = find.byKey(const Key('generate_button'));
      expect(generateButton, findsOneWidget);
      expect(find.text('Generate Pattern'), findsOneWidget);

      // Verify button is enabled
      final button = tester.widget<ElevatedButton>(generateButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should show PDF export options after pattern generation', (WidgetTester tester) async {
      // This test would require mocking the generator use case
      // For now, we'll verify the export buttons exist in the UI
      await tester.pumpWidget(createWidgetUnderTest());

      // Initially export buttons might not be visible until pattern is generated
      // This is a placeholder for when we have working integration
    });

    testWidgets('should be responsive on different screen sizes', (WidgetTester tester) async {
      // Test with mobile size
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Test with tablet size
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(createWidgetUnderTest());

      // Should still display all elements
      expect(find.text('LatticeLock Pattern Generator'), findsOneWidget);
      expect(find.byKey(const Key('grid_size_dropdown')), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should show loading state during generation', (WidgetTester tester) async {
      // This would require setting up a mock provider that returns loading state
      await tester.pumpWidget(createWidgetUnderTest());

      // Initially should not show loading
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // TODO: Add test for loading state when we have proper provider mocking
    });

    testWidgets('should display error messages when generation fails', (WidgetTester tester) async {
      // This would require setting up a mock provider that returns error state
      await tester.pumpWidget(createWidgetUnderTest());

      // TODO: Add test for error state when we have proper provider mocking
    });

    testWidgets('should handle keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Test tab navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Test arrow key navigation in dropdowns
      await tester.tap(find.byKey(const Key('grid_size_dropdown')));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // Test Enter key to select
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    });
  });
}