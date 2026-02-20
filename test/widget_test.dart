// This is a basic Flutter widget test.
//
// This test verifies the Chkobba app loads correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chkobba_tn/main.dart';

void main() {
  testWidgets('Chkobba app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChkobaApp());

    // Verify splash screen loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
