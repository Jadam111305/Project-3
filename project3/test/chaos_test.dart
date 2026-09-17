import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project3/password_controller.dart';
import 'package:project3/password_rules.dart';
import 'package:project3/screens/game_screen.dart';

class ZeroRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

Future<PasswordController> openGame(WidgetTester tester, int visible) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(
        random: ZeroRandom(),
        createGame: () => PasswordGame()..visibleCount = visible,
      ),
    ),
  );
  return tester
          .widget<TextField>(find.byKey(const ValueKey('password-input')))
          .controller!
      as PasswordController;
}

void main() {
  testWidgets(
    'cat clock starts at unlock, repeats every 5 seconds, ignores typing',
    (tester) async {
      final c = await openGame(tester, 15);
      await tester.pump(const Duration(seconds: 2));
      await tester.enterText(
        find.byKey(const ValueKey('password-input')),
        'abc',
      );
      await tester.pump(const Duration(milliseconds: 2999));
      expect(c.text, 'abc');
      await tester.pump(const Duration(milliseconds: 1));
      expect(c.text, 'abc😹');
      await tester.pump(const Duration(milliseconds: 4999));
      expect(c.text, 'abc😹');
      await tester.pump(const Duration(milliseconds: 1));
      expect(c.text, 'abc😹😹');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cat effect is absent before its rule unlocks', (tester) async {
    final c = await openGame(tester, 14);
    await tester.pump(const Duration(seconds: 20));
    expect(c.text, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mystery flips the whole game and switches to dark mode', (
    tester,
  ) async {
    await openGame(tester, 16);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );
    await tester.pump(const Duration(seconds: 7));
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('mystery-rotation')),
    );
    expect(transform.transform.entry(0, 0), closeTo(-1, 0.0001));
    expect(transform.transform.entry(1, 1), closeTo(-1, 0.0001));
    await tester.pump(const Duration(seconds: 7));
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('physical backspace prefixes once, including at the start', (
    tester,
  ) async {
    final c = await openGame(tester, 18);
    await tester.enterText(find.byKey(const ValueKey('password-input')), 'abc');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(c.text, 'aab');
    c.selection = const TextSelection.collapsed(offset: 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(c.text, 'aaab');
    await tester.pumpWidget(const SizedBox());
  });
}
