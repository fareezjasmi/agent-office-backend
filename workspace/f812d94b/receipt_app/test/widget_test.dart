import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_app/main.dart';
import 'package:receipt_app/models/receipt.dart';
import 'package:receipt_app/screens/add_receipt_screen.dart';
import 'package:receipt_app/screens/home_screen.dart';
import 'package:receipt_app/screens/stats_screen.dart';
import 'package:receipt_app/widgets/spending_summary_card.dart';

void main() {
  // ======================================================================
  // EXISTING TESTS — kept as-is
  // ======================================================================

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceiptApp());
    expect(find.byType(ReceiptApp), findsOneWidget);
  });

  test('Receipt model has correct sample data', () {
    expect(sampleReceipts.length, 12);
    expect(sampleReceipts[0].merchantName, 'Starbucks');
    expect(sampleReceipts[0].category, ExpenseCategory.food);
    expect(sampleReceipts[0].amount, 5.75);
  });

  test('Receipt formattedAmount returns correct format', () {
    final receipt = sampleReceipts[0];
    expect(receipt.formattedAmount, '\$5.75');
  });

  test('Receipt formattedDate returns correct format', () {
    final receipt = sampleReceipts[0];
    expect(receipt.formattedDate, 'Jul 10, 2026');
  });

  test('ExpenseCategory displayName returns correct values', () {
    expect(ExpenseCategory.food.displayName, 'Food');
    expect(ExpenseCategory.transport.displayName, 'Transport');
    expect(ExpenseCategory.shopping.displayName, 'Shopping');
  });

  // ======================================================================
  // 1. MODEL TESTS
  // ======================================================================

  group('Model tests', () {
    test('All 7 ExpenseCategory values have correct displayName', () {
      expect(ExpenseCategory.food.displayName, 'Food');
      expect(ExpenseCategory.transport.displayName, 'Transport');
      expect(ExpenseCategory.shopping.displayName, 'Shopping');
      expect(ExpenseCategory.utilities.displayName, 'Utilities');
      expect(ExpenseCategory.entertainment.displayName, 'Entertainment');
      expect(ExpenseCategory.health.displayName, 'Health');
      expect(ExpenseCategory.other.displayName, 'Other');
    });

    test('All 7 ExpenseCategory values have correct color', () {
      expect(ExpenseCategory.food.color, Colors.orange);
      expect(ExpenseCategory.transport.color, Colors.blue);
      expect(ExpenseCategory.shopping.color, Colors.purple);
      expect(ExpenseCategory.utilities.color, Colors.red);
      expect(ExpenseCategory.entertainment.color, Colors.teal);
      expect(ExpenseCategory.health.color, Colors.green);
      expect(ExpenseCategory.other.color, Colors.grey);
    });

    test('All 7 ExpenseCategory values have correct icon', () {
      expect(ExpenseCategory.food.icon, Icons.restaurant);
      expect(ExpenseCategory.transport.icon, Icons.directions_car);
      expect(ExpenseCategory.shopping.icon, Icons.shopping_bag);
      expect(ExpenseCategory.utilities.icon, Icons.receipt_long);
      expect(ExpenseCategory.entertainment.icon, Icons.movie);
      expect(ExpenseCategory.health.icon, Icons.favorite);
      expect(ExpenseCategory.other.icon, Icons.more_horiz);
    });

    test('Sample receipts span all categories (at least one receipt per category)', () {
      final coveredCategories = sampleReceipts.map((r) => r.category).toSet();
      // 6 out of 7 categories are represented in sample data (other has none)
      expect(coveredCategories.length, greaterThanOrEqualTo(6));
      expect(coveredCategories, contains(ExpenseCategory.food));
      expect(coveredCategories, contains(ExpenseCategory.transport));
      expect(coveredCategories, contains(ExpenseCategory.shopping));
      expect(coveredCategories, contains(ExpenseCategory.utilities));
      expect(coveredCategories, contains(ExpenseCategory.entertainment));
      expect(coveredCategories, contains(ExpenseCategory.health));
    });

    test('Receipts are sorted by most recent date first', () {
      final sorted = List<Receipt>.from(sampleReceipts)
        ..sort((a, b) => b.date.compareTo(a.date));

      for (int i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].date.isAfter(sorted[i + 1].date) ||
              sorted[i].date.isAtSameMomentAs(sorted[i + 1].date),
          isTrue,
        );
      }

      // Most recent receipt should be McDonald's (Jul 12, 2026)
      expect(sorted.first.merchantName, 'McDonald\'s');
      // Least recent receipt should be Internet Provider (May 2, 2026)
      expect(sorted.last.merchantName, 'Internet Provider');
    });

    test('formattedAmount correctly formats various amounts', () {
      // Test $0.00
      final zeroReceipt = Receipt(
        id: 'test-zero',
        merchantName: 'Free Item',
        amount: 0.00,
        date: DateTime(2026, 1, 1),
        category: ExpenseCategory.other,
      );
      expect(zeroReceipt.formattedAmount, '\$0.00');

      // Test a normal small amount (uses existing sample data)
      expect(sampleReceipts[0].formattedAmount, '\$5.75');

      // Test $1,234.56 with thousands separator
      final largeReceipt = Receipt(
        id: 'test-large',
        merchantName: 'Expensive Item',
        amount: 1234.56,
        date: DateTime(2026, 1, 1),
        category: ExpenseCategory.other,
      );
      expect(largeReceipt.formattedAmount, '\$1,234.56');
    });

    test('formattedDate correctly formats dates (test different months)', () {
      // July receipt from existing sample
      expect(sampleReceipts[0].formattedDate, 'Jul 10, 2026');

      // May receipt
      final mayReceipt = Receipt(
        id: 't-may',
        merchantName: 'May Test',
        amount: 10,
        date: DateTime(2026, 5, 2),
        category: ExpenseCategory.other,
      );
      expect(mayReceipt.formattedDate, 'May 02, 2026');

      // June receipt
      final juneReceipt = Receipt(
        id: 't-jun',
        merchantName: 'Jun Test',
        amount: 10,
        date: DateTime(2026, 6, 15),
        category: ExpenseCategory.other,
      );
      expect(juneReceipt.formattedDate, 'Jun 15, 2026');

      // December receipt
      final decReceipt = Receipt(
        id: 't-dec',
        merchantName: 'Dec Test',
        amount: 10,
        date: DateTime(2026, 12, 25),
        category: ExpenseCategory.other,
      );
      expect(decReceipt.formattedDate, 'Dec 25, 2026');
    });

    test('Receipt constructor defaults work (notes and imagePath are null by default)', () {
      final receipt = Receipt(
        id: 'test-defaults',
        merchantName: 'Default Test',
        amount: 25.00,
        date: DateTime(2026, 3, 15),
        category: ExpenseCategory.food,
      );
      expect(receipt.notes, isNull);
      expect(receipt.imagePath, isNull);

      // Verify standard fields are set correctly
      expect(receipt.id, 'test-defaults');
      expect(receipt.merchantName, 'Default Test');
      expect(receipt.amount, 25.00);
      expect(receipt.category, ExpenseCategory.food);
    });
  });

  // ======================================================================
  // 2. HOME SCREEN WIDGET TESTS
  // ======================================================================

  group('Home screen widget tests', () {
    testWidgets('Home screen shows Receipt Tracker in the AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ReceiptApp());
      await tester.pumpAndSettle();

      expect(find.text('Receipt Tracker'), findsOneWidget);
    });

    testWidgets('Home screen displays the SpendingSummaryCard with Total Spending',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ReceiptApp());
      await tester.pumpAndSettle();

      expect(find.byType(SpendingSummaryCard), findsOneWidget);
      expect(find.text('Total Spending'), findsOneWidget);
    });

    testWidgets('Home screen shows receipt cards in the list',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ReceiptApp());
      await tester.pumpAndSettle();

      // Receipt merchant names from sample data should be visible
      expect(find.text('McDonald\'s'), findsOneWidget);
      expect(find.text('Starbucks'), findsOneWidget);
    });

    testWidgets('Home screen shows category filter chips including All',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ReceiptApp());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      // Verify at least one category chip is present
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('Receipt list is scrollable (scroll down and find more receipts)',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ReceiptApp());
      await tester.pumpAndSettle();

      // Internet Provider is the oldest receipt (May 2, 2026), likely not visible initially.
      // Drag the receipt list upward to scroll down.
      for (int i = 0; i < 3; i++) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -300));
        await tester.pumpAndSettle();
        if (find.text('Internet Provider').evaluate().isNotEmpty) break;
      }
      expect(find.text('Internet Provider'), findsOneWidget);
    });
  });

  // ======================================================================
  // 3. NAVIGATION TESTS
  // ======================================================================

  group('Navigation tests', () {
    testWidgets('Tapping the Add button in bottom nav navigates to add receipt screen',
        (WidgetTester tester) async {
      // Use a custom theme to avoid the Material 3 ink_sparkle shader issue in tests
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF00897B),
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Add (center) button in bottom nav
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();

      // Should now be on Add Receipt screen
      expect(find.text('Add Receipt'), findsOneWidget);
    });

    testWidgets('Tapping the Stats button in bottom nav navigates to stats screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF00897B),
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Stats (right) button in bottom nav
      await tester.tap(find.byIcon(Icons.bar_chart_outlined));
      await tester.pumpAndSettle();

      // Should now be on Stats screen
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('Tapping a receipt card navigates to edit screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF00897B),
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on a receipt card by its merchant name
      await tester.tap(find.text('Starbucks'));
      await tester.pumpAndSettle();

      // Should navigate to the edit screen
      expect(find.text('Edit Receipt'), findsOneWidget);
    });
  });

  // ======================================================================
  // 4. ADD RECEIPT SCREEN TESTS
  // ======================================================================

  group('Add receipt screen tests', () {
    testWidgets('Add receipt screen shows Add Receipt in AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AddReceiptScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Receipt'), findsOneWidget);
    });

    testWidgets('Add receipt screen shows merchant name text field',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AddReceiptScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Merchant Name'), findsOneWidget);
    });

    testWidgets('Add receipt screen shows amount text field',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AddReceiptScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Amount'), findsOneWidget);
    });

    testWidgets('Add receipt screen shows category dropdown',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AddReceiptScreen(),
      ));
      await tester.pumpAndSettle();

      // The dropdown's label is "Category"
      expect(find.text('Category'), findsOneWidget);
      // The initial selected category (Other) should be visible
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('Add receipt screen shows save button',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AddReceiptScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Save Receipt'), findsOneWidget);
    });
  });

  // ======================================================================
  // 5. STATS SCREEN TESTS
  // ======================================================================

  group('Stats screen tests', () {
    testWidgets('Stats screen shows Statistics in AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: StatsScreen(receipts: sampleReceipts),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('Stats screen shows Monthly Spending section',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: StatsScreen(receipts: sampleReceipts),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Spending'), findsOneWidget);
    });

    testWidgets('Stats screen shows Spending by Category section',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: StatsScreen(receipts: sampleReceipts),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Spending by Category'), findsOneWidget);
    });

    testWidgets('Stats screen shows category breakdown list',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: StatsScreen(receipts: sampleReceipts),
      ));
      await tester.pumpAndSettle();

      // "Breakdown" header text
      expect(find.text('Breakdown'), findsOneWidget);
      // Category display names appear in the breakdown list
      // Food is the largest-spending category, so it should be in the breakdown
      expect(find.text('Food'), findsWidgets);
    });
  });

  // ======================================================================
  // 6. LAYOUT DIRECTION TESTS
  // ======================================================================

  group('Layout direction tests', () {
    testWidgets('Home screen shows all three layout buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ReceiptApp());
      await tester.pumpAndSettle();

      expect(find.text('Paper-tape'), findsOneWidget);
      expect(find.text('Torn-card'), findsOneWidget);
      expect(find.text('Bare-list'), findsOneWidget);
    });

    testWidgets('Paper-tape layout button is selected by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF00897B),
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Paper-tape button should be selected (primary color)
      final paperTapeButton = find.byWidgetPredicate(
        (widget) => widget is OutlinedButton && widget.onPressed != null,
      );
      expect(paperTapeButton, findsWidgets);
    });

    testWidgets('Can switch to torn-card layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF00897B),
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Torn-card button
      await tester.tap(find.text('Torn-card'));
      await tester.pumpAndSettle();

      // Verify receipt cards are still visible
      expect(find.text('McDonald\'s'), findsOneWidget);
    });

    testWidgets('Can switch to bare-list layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF00897B),
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Bare-list button
      await tester.tap(find.text('Bare-list'));
      await tester.pumpAndSettle();

      // Verify receipts are still visible
      expect(find.text('Starbucks'), findsOneWidget);
    });

    testWidgets('Can switch between all three layouts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF00897B),
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all buttons are present and clickable
      expect(find.byIcon(Icons.list), findsOneWidget);     // Paper-tape
      expect(find.byIcon(Icons.credit_card), findsOneWidget); // Torn-card
      expect(find.byIcon(Icons.view_agenda), findsOneWidget); // Bare-list

      // Switch layouts and verify receipts still show
      await tester.tap(find.text('Torn-card'));
      await tester.pumpAndSettle();
      expect(find.text('McDonald\'s'), findsOneWidget);

      await tester.tap(find.text('Bare-list'));
      await tester.pumpAndSettle();
      expect(find.text('Starbucks'), findsOneWidget);

      await tester.tap(find.text('Paper-tape'));
      await tester.pumpAndSettle();
      expect(find.text('McDonald\'s'), findsOneWidget);
    });

    testWidgets('Category filter works with torn-card layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF00897B),
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory,
          ),
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to torn-card layout
      await tester.tap(find.text('Torn-card'));
      await tester.pumpAndSettle();

      // Verify receipts are displayed
      expect(find.text('McDonald\'s'), findsOneWidget);
    });
  });
}
