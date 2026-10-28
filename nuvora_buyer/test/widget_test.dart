// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:nuvora_buyer/main.dart';

void main() {
  testWidgets('shows Buyer sign-in and registration entry point', (WidgetTester tester) async {
    await tester.pumpWidget(const NuvoraBuyerApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New to Nuvora? Create an account'), findsOneWidget);
  });
}
