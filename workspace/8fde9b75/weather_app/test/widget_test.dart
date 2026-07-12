import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

void main() {
  testWidgets('Weather app displays empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());

    // Verify that the empty state is shown
    expect(find.text('Weather App'), findsOneWidget);
    expect(find.text('Search for a city to see the weather'), findsOneWidget);
  });
}
