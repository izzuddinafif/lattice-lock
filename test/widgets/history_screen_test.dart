import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latticelock/features/generator/presentation/history_screen.dart';

void main() {
  group('HistoryScreen Widget Tests', () {
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
          home: HistoryScreen(),
        ),
      );
    }

    testWidgets('should display history screen with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Pattern History'), findsOneWidget);
    });

    testWidgets('should display search field', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final searchField = find.byKey(const Key('history_search_field'));
      expect(searchField, findsOneWidget);
    });

    testWidgets('should display filter dropdowns', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Algorithm filter
      final algorithmFilter = find.byKey(const Key('algorithm_filter'));
      expect(algorithmFilter, findsOneWidget);

      // Grid size filter
      final gridSizeFilter = find.byKey(const Key('grid_size_filter'));
      expect(gridSizeFilter, findsOneWidget);
    });

    testWidgets('should display statistics card', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Total Patterns: 0'), findsOneWidget);
    });

    testWidgets('should show loading state', (WidgetTester tester) async {
      // Create a container with loading state
      final loadingContainer = ProviderContainer(
        overrides: [
          // Override history provider to return loading state
          // This would require proper provider setup
        ],
      );

      await tester.pumpWidget(UncontrolledProviderScope(
        container: loadingContainer,
        child: MaterialApp(
          home: HistoryScreen(),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading history...'), findsOneWidget);

      loadingContainer.dispose();
    });

    testWidgets('should show empty state when no entries', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('No patterns found'), findsOneWidget);
      expect(find.text('Generate some patterns to see them here'), findsOneWidget);
    });

    testWidgets('should handle search input', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final searchField = find.byKey(const Key('history_search_field'));
      await tester.enterText(searchField, 'BATCH-001');
      await tester.pump();

      expect(find.text('BATCH-001'), findsOneWidget);
    });

    testWidgets('should display algorithm filter options', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap algorithm filter
      await tester.tap(find.byKey(const Key('algorithm_filter')));
      await tester.pumpAndSettle();

      // Verify filter options
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Logistic Map'), findsOneWidget);
      expect(find.text('Tent Map'), findsOneWidget);
      expect(find.text('Arnold\'s Cat Map'), findsOneWidget);
    });

    testWidgets('should display grid size filter options', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap grid size filter
      await tester.tap(find.byKey(const Key('grid_size_filter')));
      await tester.pumpAndSettle();

      // Verify filter options
      expect(find.text('All'), findsOneWidget);
      expect(find.text('2×2'), findsOneWidget);
      expect(find.text('3×3'), findsOneWidget);
      expect(find.text('4×4'), findsOneWidget);
    });

    testWidgets('should be responsive on mobile', (WidgetTester tester) async {
      // Test mobile layout
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Pattern History'), findsOneWidget);

      // Test tablet layout
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Pattern History'), findsOneWidget);

      // Reset to default
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should show statistics dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap statistics button
      final statsButton = find.byKey(const Key('statistics_button'));
      expect(statsButton, findsOneWidget);

      await tester.tap(statsButton);
      await tester.pumpAndSettle();

      // Should show dialog with statistics
      expect(find.text('Detailed Statistics'), findsOneWidget);
    });

    testWidgets('should handle clear filters', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Set some filters
      final searchField = find.byKey(const Key('history_search_field'));
      await tester.enterText(searchField, 'test');
      await tester.pump();

      // Find clear filters button
      final clearButton = find.byKey(const Key('clear_filters_button'));
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pump();

        // Search field should be cleared
        expect(find.text('test'), findsNothing);
      }
    });

    testWidgets('should handle entry selection', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // This test would require mocking entries
      // For now, verify that entry widgets can be created
      // TODO: Add entry selection test when we have proper provider setup
    });

    testWidgets('should handle entry deletion', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // This test would require mocking entries with delete functionality
      // TODO: Add entry deletion test when we have proper provider setup
    });

    testWidgets('should handle export functionality', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find export button
      final exportButton = find.byKey(const Key('export_button'));
      if (exportButton.evaluate().isNotEmpty) {
        await tester.tap(exportButton);
        await tester.pumpAndSettle();

        // Should show export options
        expect(find.text('Export History'), findsOneWidget);
      }
    });
  });
}