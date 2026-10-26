import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickcash_app/screens/collector/collector_dashboard_screen.dart';

void main() {
  testWidgets('Collector dashboard displays the main heading and summary',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CollectorDashboardScreen()),
    );

    expect(find.text('Good day, Collector!'), findsOneWidget);
    expect(find.text('Assigned borrowers'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('Collector can filter borrowers by name', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CollectorDashboardScreen()),
    );

    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Sanduni');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sanduni Fernando'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sanduni Fernando'), findsOneWidget);
    expect(find.text('Nimal Perera'), findsNothing);
  });
}
