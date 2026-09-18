import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project3/challenges.dart';
import 'package:project3/password_controller.dart';
import 'package:project3/password_rules.dart';
import 'package:project3/screens/game_screen.dart';

import 'password_rules_test.dart' show winningPassword, testDate;

void main() {
  test(
    'every scramble has exactly the answer letters and accepts only its answer',
    () {
      for (var i = 0; i < anagramChallenges.length; i++) {
        final challenge = anagramChallenges[i];
        final letters = challenge.scrambled.toLowerCase().split('')..sort();
        final answerLetters = challenge.answer.split('')..sort();
        expect(letters, answerLetters);
        expect(challenge.scrambled.toLowerCase(), isNot(challenge.answer));
        final game = PasswordGame(anagramIndex: i);
        expect(game.rules[11].id, 'italic');
        expect(game.rules[12].id, 'anagram');
        expect(game.rules[13].id, 'selfLength');
        expect(
          game.rules[12].isSatisfied(
            'prefix${challenge.answer.toUpperCase()}suffix',
            true,
          ),
          isTrue,
        );
        expect(game.rules[12].isSatisfied(challenge.scrambled, true), isFalse);
        expect(game.rules[12].isSatisfied('wronganswer', true), isFalse);
      }
    },
  );

  testWidgets('anagram appears as rule 13 and blocks rule 14 until solved', (
    tester,
  ) async {
    final game = PasswordGame(
      verseIndex: 0,
      mathIndex: 0,
      anagramIndex: 0,
      now: () => testDate,
    )..visibleCount = 12;
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(createGame: () => game)),
    );
    final input = find.byKey(const ValueKey('password-input'));
    final controller =
        tester.widget<TextField>(input).controller! as PasswordController;
    Future<void> enterAndFormat(String text) async {
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, text);
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.length,
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('italic-control')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('italic-control')));
      await tester.pump(const Duration(milliseconds: 700));
    }

    await enterAndFormat(winningPassword(game, includeAnagram: false));
    expect(find.byKey(const ValueKey('rule-anagram')), findsOneWidget);
    expect(find.byKey(const ValueKey('rule-selfLength')), findsNothing);
    expect(find.textContaining('TENALP'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('rule-selfLength')), findsNothing);
    await enterAndFormat(winningPassword(game));
    expect(find.byKey(const ValueKey('rule-selfLength')), findsOneWidget);
    expect(find.textContaining('TENALP'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
