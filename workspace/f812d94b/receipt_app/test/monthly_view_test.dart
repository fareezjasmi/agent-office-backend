import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_app/models/receipt.dart';
import 'package:receipt_app/screens/monthly_view_screen.dart';

void main() {
  group('MonthlyViewScreen tests', () {
    testWidgets('MonthlyViewScreen displays month and year', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MonthlyViewScreen(receipts: sampleReceipts),
          theme: ThemeData(colorSchemeSeed: const Color(0xFF00897B)),
        ),
      );

      // Verify month/year is displayed in the header
      expect(find.text('JULY 2026'), findsWidgets);
    });

    testWidgets('MonthlyViewScreen shows total spending card', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MonthlyViewScreen(receipts: sampleReceipts),
          theme: ThemeData(colorSchemeSeed: const Color(0xFF00897B)),
        ),
      );

      expect(find.text('Total Spending'), findsOneWidget);
    });

    testWidgets('MonthlyViewScreen shows receipts list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MonthlyViewScreen(receipts: sampleReceipts),
          theme: ThemeData(colorSchemeSeed: const Color(0xFF00897B)),
        ),
      );

      // Should have a ListView with receipts
      expect(find.byType(ListView), findsOneWidget);
      // Should find at least one receipt card
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('MonthlyViewScreen can navigate to previous month', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MonthlyViewScreen(receipts: sampleReceipts),
          theme: ThemeData(colorSchemeSeed: const Color(0xFF00897B)),
        ),
      );

      // Click previous month button
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Should now show June 2026
      expect(find.text('JUNE 2026'), findsWidgets);
    });

    testWidgets('MonthlyViewScreen can navigate to next month', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MonthlyViewScreen(receipts: sampleReceipts),
          theme: ThemeData(colorSchemeSeed: const Color(0xFF00897B)),
        ),
      );

      // Click next month button
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Should now show August 2026
      expect(find.text('AUGUST 2026'), findsWidgets);
    });

    testWidgets('MonthlyViewScreen shows calendar navigation buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MonthlyViewScreen(receipts: sampleReceipts),
          theme: ThemeData(colorSchemeSeed: const Color(0xFF00897B)),
        ),
      );

      // Should have chevron buttons for month navigation
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('MonthlyViewScreen has back button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MonthlyViewScreen(receipts: sampleReceipts),
          theme: ThemeData(colorSchemeSeed: const Color(0xFF00897B)),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('MonthlyViewScreen shows empty state when no receipts', (WidgetTester tester) async {
      // Create receipts in different months
      final receipts = [
        Receipt(
          id: 'r1',
          merchantName: 'Test Store',
          amount: 50.00,
          date: DateTime(2025, 1, 15),
          category: ExpenseCategory.shopping,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MonthlyViewScreen(receipts: receipts),
          theme: ThemeData(colorSchemeSeed: const Color(0xFF00897B)),
        ),
      );

      // Current month (July 2026) has no receipts
      expect(find.text('No receipts this month'), findsOneWidget);
    });
  });
}
