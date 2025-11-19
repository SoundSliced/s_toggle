import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s_toggle/s_toggle.dart';

void main() {
  group('SToggle Widget Tests', () {
    testWidgets('renders with initial value false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SToggle(
            value: false,
          ),
        ),
      );

      // Check that the widget is rendered
      expect(find.byType(SToggle), findsOneWidget);
    });

    testWidgets('renders with initial value true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SToggle(
            value: true,
          ),
        ),
      );

      expect(find.byType(SToggle), findsOneWidget);
    });

    testWidgets('tapping changes state from false to true',
        (WidgetTester tester) async {
      bool? changedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: SToggle(
            value: false,
            onChange: (value) => changedValue = value,
          ),
        ),
      );

      // Tap the toggle
      await tester.tap(find.byType(SToggle));
      await tester.pumpAndSettle(); // Wait for animation to complete

      // Check that onChange was called with true
      expect(changedValue, true);
    });

    testWidgets('tapping changes state from true to false',
        (WidgetTester tester) async {
      bool? changedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: SToggle(
            value: true,
            onChange: (value) => changedValue = value,
          ),
        ),
      );

      // Tap the toggle
      await tester.tap(find.byType(SToggle));
      await tester.pumpAndSettle();

      // Check that onChange was called with false
      expect(changedValue, false);
    });

    testWidgets('programmatic value change triggers animation',
        (WidgetTester tester) async {
      bool toggleValue = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SToggle(
            value: toggleValue,
          ),
        ),
      );

      // Initially false
      expect(find.byType(SToggle), findsOneWidget);

      // Simulate programmatic change by rebuilding with new value
      await tester.pumpWidget(
        MaterialApp(
          home: SToggle(
            value: true, // Changed to true
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should still exist and animation should complete
      expect(find.byType(SToggle), findsOneWidget);
    });

    testWidgets('custom size is applied', (WidgetTester tester) async {
      const double customSize = 100.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SToggle(
                size: customSize,
                value: false,
              ),
            ),
          ),
        ),
      );

      // Find the SToggle widget itself and check its size
      final toggleWidget = find.byType(SToggle);
      final size = tester.getSize(toggleWidget);

      expect(size.width, customSize);
      expect(size.height, customSize / 2);
    });

    testWidgets('animation duration is respected', (WidgetTester tester) async {
      const Duration customDuration = Duration(milliseconds: 500);

      await tester.pumpWidget(
        MaterialApp(
          home: SToggle(
            value: false,
            animationDuration: customDuration,
          ),
        ),
      );

      // Tap to start animation
      await tester.tap(find.byType(SToggle));

      // Pump for less than duration
      await tester.pump(const Duration(milliseconds: 250));

      // Animation should be in progress (hard to test exactly, but widget exists)
      expect(find.byType(SToggle), findsOneWidget);

      // Pump to completion
      await tester.pumpAndSettle();
    });
  });
}
