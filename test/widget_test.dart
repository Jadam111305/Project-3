import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project3/main.dart';
import 'package:project3/password_controller.dart';
import 'package:project3/password_rules.dart';
import 'package:project3/screens/game_screen.dart';

import 'password_rules_test.dart' show winningPassword, testDate;

void main() {
  testWidgets('start opens one rule and reveals only one more at a time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('START GAME'));
    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rule-length')), findsOneWidget);
    expect(find.byKey(const ValueKey('rule-number')), findsNothing);
    await tester.enterText(find.byType(TextField), 'David123!');
    await tester.pump(const Duration(milliseconds: 699));
    expect(find.byKey(const ValueKey('rule-number')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('rule-number')), findsOneWidget);
    expect(find.byKey(const ValueKey('rule-uppercase')), findsNothing);
    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('rule-number')), findsOneWidget);
    expect(find.byKey(const ValueKey('rule-uppercase')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('complete game, italic formatting, regression and restart', (
    tester,
  ) async {
    final game = PasswordGame(verseIndex: 0, mathIndex: 0, now: () => testDate);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          createGame: () =>
              PasswordGame(verseIndex: 0, mathIndex: 0, now: () => testDate)
                ..temperatureF = 72,
        ),
      ),
    );
    final password = winningPassword(game);
    await tester.enterText(find.byType(TextField), password);
    for (var i = 0; i < 11; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(find.byKey(const ValueKey('rule-italic')), findsOneWidget);
    expect(find.byKey(const ValueKey('rule-selfLength')), findsNothing);
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('password-input')),
    );
    final controller = input.controller! as PasswordController;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: password.length,
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('italic-control')));
    await tester.tap(find.byKey(const ValueKey('italic-control')));
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(find.text('Password accepted!'), findsOneWidget);

    final span = controller.buildTextSpan(
      context: tester.element(find.byKey(const ValueKey('password-input'))),
      style: const TextStyle(),
      withComposing: false,
    );
    expect(span.toPlainText(), password);
    expect(
      (span.children!.first as TextSpan).style!.fontStyle,
      FontStyle.italic,
    );
    expect((span.children![1] as TextSpan).style!.fontStyle, FontStyle.italic);

    // Winning freezes the password and stops both disruptive clocks.
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('password-input')))
          .readOnly,
      isTrue,
    );
    await tester.pump(const Duration(seconds: 30));
    expect(controller.text, password);
    await tester.ensureVisible(find.byKey(const ValueKey('play-again')));
    await tester.tap(find.byKey(const ValueKey('play-again')));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(controller.allConsonantsItalic, isFalse);
    expect(find.byKey(const ValueKey('rule-number')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
