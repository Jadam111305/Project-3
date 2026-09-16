import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project3/main.dart';

void main() {
  testWidgets('Home fits a small phone and start stays on home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(find.text('A PASSWORD GAME'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('START GAME'));
    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();
    expect(find.text('A PASSWORD GAME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
