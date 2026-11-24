
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickcash_frontend/main.dart';

void main() {
  testWidgets('QuickCash login screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickCashApp());

    expect(find.text('QuickCash'), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
