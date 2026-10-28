import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nuvora_app/main.dart';
import 'package:nuvora_app/features/auth/register_screen.dart';
import 'package:nuvora_app/features/auth/rider_email_otp_sheet.dart';

void main() {
  testWidgets('Email Verify action is visible beside the label before entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    final emailField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.keyboardType == TextInputType.emailAddress,
    );
    await tester.ensureVisible(emailField);
    await tester.pumpAndSettle();

    final verifyAction = find.byKey(const Key('rider-email-verify'));
    final emailLabel = find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().startsWith('Email'),
    );
    expect(verifyAction, findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(
      tester.getRect(verifyAction).center.dy,
      closeTo(tester.getRect(emailLabel).center.dy, 4),
    );
  });

  testWidgets('Valid rider email displays its Verify action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    final emailField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.keyboardType == TextInputType.emailAddress,
    );
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'rider@example.com');
    await tester.pump();

    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('✓ Verified'), findsNothing);
    final verifyLabelRect = tester.getRect(find.text('Verify'));
    final emailLabelRect = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().startsWith('Email'),
      ),
    );
    expect(
      (verifyLabelRect.center.dy - emailLabelRect.center.dy).abs(),
      lessThan(4),
    );
  });

  testWidgets('Rider email code entry is presented in a bottom sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      const RiderEmailOtpSheet(email: 'rider@example.com'),
                ),
                child: const Text('Open verification'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('rider@example.com'), findsOneWidget);
    expect(find.text('Verify email'), findsOneWidget);
    expect(find.text('Resend code'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('Login screen renders and opens registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // The login page scrolls, so bring the register link on screen first.
    await tester.scrollUntilVisible(
      find.text('Create an account'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Create an account'));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create rider account'), findsOneWidget);
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    expect(find.text('Please provide your personal details.'), findsOneWidget);
    // The first step's fields sit below the progress bar, off-screen in this
    // viewport, so assert the step's own content is what rendered.
    // Field labels render as RichText spans (with a required-asterisk
    // suffix), so match on the span's plain text.
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().startsWith('Last Name'),
      ),
      findsWidgets,
    );
    expect(find.text('Account Security'), findsOneWidget);
  });
}
