// This is a basic Flutter widget test for the E-Paper PDF Viewer app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:epaper/main.dart';

void main() {
  testWidgets('E-Paper app loads and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app shows the correct title.
    expect(find.text('E-Paper PDF Viewer'), findsOneWidget);
    
    // Wait for any async operations to complete
    await tester.pumpAndSettle();
    
    // The app should show some loading or content state
    // Since the HTTP requests will fail in test environment (status 400),
    // the app should fall back to mock data or show an error state
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App shows PDF list screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Wait for the app to settle
    await tester.pumpAndSettle();
    
    // The app should show the PDF list screen as the home screen
    // Even if network requests fail, the app should still render
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });
}
