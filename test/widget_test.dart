import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_portfolio/main.dart';

void main() {
  testWidgets('Home dashboard shows welcome greeting and activity cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PortfolioApp());

    // Default profile name shown on first launch.
    expect(find.textContaining('Welcome back'), findsOneWidget);

    // The three menu cards should be visible on the dashboard.
    expect(find.text('Activity 1'), findsOneWidget);
    expect(find.text('Activity 2'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
