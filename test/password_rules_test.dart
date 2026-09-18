import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project3/challenges.dart';
import 'package:project3/password_rules.dart';
import 'package:project3/rule_words.dart';

final testDate = DateTime(2026, 9, 17);

bool passes(PasswordGame game, String id, String password, bool italic) => game
    .rules
    .singleWhere((rule) => rule.id == id)
    .isSatisfied(password, italic);

String winningPassword(PasswordGame game, {bool includeAnagram = true}) {
  final base =
      'David! Washington ${game.verse.language} ${game.math.answer} helium 😀 ${includeAnagram ? game.anagram.answer : ''} ${game.today} 72 .pdf .png .txt ';
  for (var length = base.characters.length + 3; length < 300; length++) {
    if (!isPrime(length)) continue;
    final candidate = '$base$length ';
    if (candidate.characters.length <= length) {
      return candidate + 'a' * (length - candidate.characters.length);
    }
  }
  throw StateError('No solution found');
}

void main() {
  test('temperature matches the signed whole number, not a substring', () {
    final game = PasswordGame();
    expect(passes(game, 'temperature', '72', false), isFalse);
    game.temperatureF = -5;
    expect(passes(game, 'temperature', 'temp-5F', false), isTrue);
    for (final password in ['5', '15', '-50', '-5.5', '1.5', '35']) {
      expect(passes(game, 'temperature', password, false), isFalse);
    }
    game.temperatureF = 72;
    expect(passes(game, 'temperature', 'temp72F', false), isTrue);
    expect(passes(game, 'temperature', '-72', false), isFalse);
    expect(passes(game, 'temperature', '172', false), isFalse);
  });

  test('file extensions require three distinct known extensions with dots', () {
    expect(fileExtensions('.pdf.PDF.pdf').length, 1);
    expect(fileExtensions('.pdf.png.txt'), {'pdf', 'png', 'txt'});
    expect(fileExtensions('pdf png txt'), isEmpty);
    expect(fileExtensions('.pdfake .pngish .nonsense'), isEmpty);
    final game = PasswordGame();
    expect(passes(game, 'extensions', '.PDF.png.txt', false), isTrue);
    expect(passes(game, 'extensions', '.pdf.PDF.txt', false), isFalse);
  });
  test(
    'all 1000 verse, math and anagram combinations can satisfy every rule',
    () {
      expect(verseChallenges.length, 10);
      expect(mathChallenges.length, 10);
      for (var verse = 0; verse < 10; verse++) {
        for (var math = 0; math < 10; math++) {
          for (var anagram = 0; anagram < anagramChallenges.length; anagram++) {
            final game = PasswordGame(
              verseIndex: verse,
              mathIndex: math,
              anagramIndex: anagram,
              now: () => testDate,
            );
            final password = winningPassword(game);
            game.temperatureF = 72;
            expect(game.rules.length, 20);
            expect(game.visibleCount, 1);
            expect(game.hasWon(password, true), isFalse);
            for (var visible = 2; visible <= game.rules.length; visible++) {
              expect(game.revealNext(password, true), isTrue);
              expect(game.visibleCount, visible);
            }
            expect(game.hasWon(password, true), isTrue);
            expect(game.hasWon(password, false), isFalse);
            expect(
              game.hasWon(password.replaceFirst('David', 'david'), true),
              isFalse,
            );
          }
        }
      }
    },
  );

  test('a broken earlier rule blocks progression without hiding rules', () {
    final game = PasswordGame();
    expect(game.revealNext('abcdefgh', false), isTrue);
    expect(game.visibleCount, 2);
    expect(game.revealNext('1', false), isFalse);
    expect(game.visibleCount, 2);
    expect(game.revealNext('abcdefgh1', false), isTrue);
    expect(game.visibleCount, 3);
  });

  test(
    'length uses visible characters, including joined and skin-tone emoji',
    () {
      final game = PasswordGame();
      expect(passes(game, 'length', '123456😀', false), isFalse);
      expect(passes(game, 'length', '1234567👨‍👩‍👧‍👦', false), isTrue);
      expect('👍🏽'.characters.length, 1);
      expect(isPrime(1), isFalse);
      expect(isPrime(2), isTrue);
      expect(isPrime(49), isFalse);
      expect(isPrime(67), isTrue);
    },
  );

  test('math and self-length require complete digit groups', () {
    expect(containsNumber('answer12!', 12), isTrue);
    expect(containsNumber('answer112!', 12), isFalse);
    expect(containsNumber('answer120!', 12), isFalse);
    final game = PasswordGame();
    expect(passes(game, 'selfLength', 'abcde7!', false), isTrue);
    expect(passes(game, 'selfLength', 'abcde7!!', false), isFalse);
  });

  test('emoji recognition excludes plain digits, letters and modifiers', () {
    for (final emoji in [
      '😀',
      '❤️',
      '🚀',
      '👍🏽',
      '👨‍👩‍👧‍👦',
      '🇺🇸',
      '1️⃣',
    ]) {
      expect(containsEmoji(emoji), isTrue, reason: emoji);
    }
    for (final text in ['password123!', 'David', '©', '🏽', '🇺', '☇', '🜀']) {
      expect(containsEmoji(text), isFalse, reason: text);
    }
  });

  test('names accept full spellings without case sensitivity', () {
    final game = PasswordGame();
    expect(elementNames.toSet().length, 121);
    for (final element in elementNames) {
      expect(passes(game, 'element', element.toUpperCase(), false), isTrue);
    }
    expect(passes(game, 'element', 'He', false), isFalse);
    for (final president in presidentSurnames) {
      expect(passes(game, 'president', president.toUpperCase(), false), isTrue);
    }
    expect(passes(game, 'president', 'notapresident', false), isFalse);
  });

  test('date accepts leading zeros and updates across midnight', () {
    var now = testDate;
    final game = PasswordGame(now: () => now);
    expect(passes(game, 'date', '09/17/2026', false), isTrue);
    expect(passes(game, 'date', '9/17/2026', false), isTrue);
    for (final invalid in [
      '19/17/2026',
      '9/17/20260',
      '9/17/26',
      '17/9/2026',
      '9/16/2026',
    ]) {
      expect(passes(game, 'date', invalid, false), isFalse);
    }
    now = now.add(const Duration(days: 1));
    expect(passes(game, 'date', '9/17/2026', false), isFalse);
    expect(passes(game, 'date', '9/18/2026', false), isTrue);
  });
}
