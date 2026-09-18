import 'dart:math';

import 'package:flutter/material.dart';

import 'challenges.dart';
import 'rule_words.dart';

final consonants = RegExp(r'[b-df-hj-np-tv-z]', caseSensitive: false);
// Unicode binary properties work in the VM and modern browsers, but the
// analyzer's regexp lint does not yet parse this property. Covered by tests.
// ignore: valid_regexps
final _emojiCodePoint = RegExp(r'\p{Emoji}', unicode: true);

bool isPrime(int value) {
  if (value < 2) return false;
  for (var divisor = 2; divisor * divisor <= value; divisor++) {
    if (value % divisor == 0) return false;
  }
  return true;
}

bool containsNumber(String password, int number) =>
    RegExp(r'\d+')
        .allMatches(password)
        .any((match) => match.group(0) == number.toString());

bool containsTemperature(String password, int temperature) =>
    RegExp(r'(?<![\d.+-])-?\d+(?![\d.])')
        .allMatches(password)
        .any((match) => int.tryParse(match.group(0)!) == temperature);

final knownExtensions =
    ('txt pdf doc docx xls xlsx ppt pptx csv tsv json xml yaml yml html htm css '
            'js ts jsx tsx py java c cpp h hpp dart rs go rb php sql md rtf '
            'jpg jpeg png gif webp svg bmp ico mp3 wav ogg flac mp4 mov avi mkv webm '
            'zip rar 7z gz tar exe apk ipa sh bat ps1')
        .split(' ')
        .toSet();

Set<String> fileExtensions(String password) =>
    RegExp(r'\.([a-z0-9]+)', caseSensitive: false)
        .allMatches(password)
        .map((match) => match.group(1)!.toLowerCase())
        .where(knownExtensions.contains)
        .toSet();

bool containsEmoji(String password) {
  if (RegExp(r'[0-9#*]\uFE0F?\u20E3', unicode: true).hasMatch(password)) {
    return true;
  }
  return password.characters.any((character) {
    final runes = character.runes.toList();
    if (runes.length >= 2 &&
        runes.take(2).every((r) => r >= 0x1F1E6 && r <= 0x1F1FF)) {
      return true;
    }
    return runes.any((r) {
      // Digits need a keycap, flags need a pair, and skin tones need a base.
      if (r < 0x80 ||
          (r >= 0x1F1E6 && r <= 0x1F1FF) ||
          (r >= 0x1F3FB && r <= 0x1F3FF)) {
        return false;
      }
      if ((r == 0xA9 || r == 0xAE || r == 0x2122) && !runes.contains(0xFE0F)) {
        return false;
      }
      return _emojiCodePoint.hasMatch(String.fromCharCode(r));
    });
  });
}

String dateLabel(DateTime date) => [date.month, date.day, date.year].join('/');

bool containsDate(String password, DateTime date) =>
    RegExp(r'(?<!\d)(\d{1,2})/(\d{1,2})/(\d{4})(?!\d)')
        .allMatches(password)
        .any(
          (match) =>
              int.parse(match.group(1)!) == date.month &&
              int.parse(match.group(2)!) == date.day &&
              int.parse(match.group(3)!) == date.year,
        );

class PasswordRule {
  const PasswordRule(
    this.id,
    this.description,
    this.isSatisfied, {
    this.detail,
  });
  final String id;
  final String description;
  final String? detail;
  final bool Function(String password, bool italicConsonants) isSatisfied;
}

class PasswordGame {
  PasswordGame({
    Random? random,
    DateTime Function()? now,
    int? verseIndex,
    int? mathIndex,
    int? anagramIndex,
  }) : _now = now ?? DateTime.now {
    final picker = random ?? Random();
    verse =
        verseChallenges[verseIndex ?? picker.nextInt(verseChallenges.length)];
    math = mathChallenges[mathIndex ?? picker.nextInt(mathChallenges.length)];
    anagram =
        anagramChallenges[anagramIndex ??
            picker.nextInt(anagramChallenges.length)];
    rules = [
      PasswordRule(
        'length',
        'Your password must be at least 8 characters.',
        (p, _) => p.characters.length >= 8,
      ),
      PasswordRule(
        'number',
        'Your password must include a number.',
        (p, _) => RegExp(r'[0-9]').hasMatch(p),
      ),
      PasswordRule(
        'uppercase',
        'Your password must include an uppercase letter.',
        (p, _) => RegExp(r'[A-Z]').hasMatch(p),
      ),
      PasswordRule(
        'special',
        'Your password must include a special character.',
        (p, _) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(p),
      ),
      PasswordRule(
        'david',
        'Your password must include "David".',
        (p, _) => p.contains('David'),
        detail: 'Use a capital D.',
      ),
      PasswordRule(
        'president',
        'Your password must include a US president’s last name.',
        (p, _) => presidentSurnames.any(p.toLowerCase().contains),
        detail: 'Names are not case-sensitive.',
      ),
      PasswordRule(
        'language',
        'Your password must include the language of this verse.',
        (p, _) => [
          verse.language,
          ...verse.aliases,
        ].any((language) => p.toLowerCase().contains(language.toLowerCase())),
        detail: verse.excerpt,
      ),
      PasswordRule(
        'math',
        'Your password must include the answer to this equation.',
        (p, _) => containsNumber(p, math.answer),
        detail: '${math.equation}\nKeep the answer separate from other digits.',
      ),
      PasswordRule(
        'element',
        'Your password must include the full name of a periodic table element.',
        (p, _) => elementNames.any(p.toLowerCase().contains),
        detail: 'An element’s name, not its symbol. Not case-sensitive.',
      ),
      PasswordRule(
        'prime',
        'The length of your password must be a prime number.',
        (p, _) => isPrime(p.characters.length),
        detail: 'A prime is greater than 1 and divisible only by 1 and itself.',
      ),
      PasswordRule(
        'emoji',
        'Your password must include an emoji.',
        (p, _) => containsEmoji(p),
      ),
      PasswordRule(
        'italic',
        'All consonants must be italic.',
        (p, italic) => italic && consonants.hasMatch(p),
        detail: 'Highlight text, then use “Italic selected characters”. Every English consonant, including Y, must be italic. New characters start plain.',
      ),
      PasswordRule(
        'anagram',
        'Solve this anagram and include the answer in your password.',
        (p, _) => p.toLowerCase().contains(anagram.answer),
        detail:
            '${anagram.scrambled}\nClue: ${anagram.hint}\nThe answer is not case-sensitive.',
      ),
      PasswordRule(
        'selfLength',
        'Your password must include the length of your password.',
        (p, _) => containsNumber(p, p.characters.length),
        detail: 'Count every visible character, including spaces and emojis. Keep the number separate from other digits.',
      ),
      PasswordRule(
        'date',
        'Your password must include the current date in month/day/year format.',
        (p, _) => containsDate(p, _now()),
        detail: 'Use your device’s local date. Leading zeros are allowed.',
      ),
      PasswordRule(
        'cats',
        'Cat invasion! 😹',
        (p, _) => true,
        detail: 'Nothing to solve. A laughing cat joins your password every 5 seconds from now on.',
      ),
      PasswordRule('mystery', '??', (p, _) => true),
      PasswordRule(
        'temperature',
        'Your password must include the temperature of your current city in Fahrenheit.',
        (p, _) => temperatureF != null && containsTemperature(p, temperatureF!),
        detail: 'Use the whole-degree temperature shown below, including a minus sign if it is below zero.',
      ),
      PasswordRule(
        'backspace',
        'Every Backspace adds a random character at the start of your password.',
        (p, _) => true,
        detail: 'Nothing to solve. The effect stays active for the rest of the game.',
      ),
      PasswordRule(
        'extensions',
        'Your password must include at least 3 different file extensions.',
        (p, _) => fileExtensions(p).length >= 3,
        detail: 'Include the dots, for example .pdf .png .txt. Repeating an extension does not count twice.',
      ),
    ];
  }

  final DateTime Function() _now;
  late final VerseChallenge verse;
  late final MathChallenge math;
  late final AnagramChallenge anagram;
  late final List<PasswordRule> rules;
  int visibleCount = 1;
  int? temperatureF;

  bool isUnlocked(String id) => rules.take(visibleCount).any((r) => r.id == id);

  String get today => dateLabel(_now());
  bool passes(int index, String password, bool italic) =>
      rules[index].isSatisfied(password, italic);
  int passedCount(String password, bool italic) => rules
      .take(visibleCount)
      .where((r) => r.isSatisfied(password, italic))
      .length;
  bool allVisiblePass(String password, bool italic) =>
      passedCount(password, italic) == visibleCount;
  bool hasWon(String password, bool italic) =>
      visibleCount == rules.length && allVisiblePass(password, italic);

  // Called once per reveal animation; previously unlocked rules stay visible.
  bool revealNext(String password, bool italic) {
    if (visibleCount == rules.length || !allVisiblePass(password, italic)) {
      return false;
    }
    visibleCount++;
    return true;
  }
}
