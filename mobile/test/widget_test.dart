import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localpro/main.dart';

void main() {
  testWidgets('Signed-out accounts explain how to continue', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SignInPanel(onSignedIn: () {})),
      ),
    );
    expect(find.text('Make yourself at home.'), findsOneWidget);
    expect(find.text('Log in or create account ↗'), findsOneWidget);
  });
  test('API timestamps are displayed consistently in East Africa Time', () {
    expect(localTime('2026-10-24T07:00:00'), '24/10/2026 · 10:00 EAT');
    expect(localTime('2026-10-24T07:00:00Z'), '24/10/2026 · 10:00 EAT');
  });
}
