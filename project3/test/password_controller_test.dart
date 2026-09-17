import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project3/password_controller.dart';

void main() {
  test('only selected characters become italic, including selected vowels', () {
    final c = PasswordController()..text = 'David';
    addTearDown(c.dispose);
    c.selection = const TextSelection(baseOffset: 1, extentOffset: 2);
    c.toggleSelectedItalics();
    expect(c.isItalicAt(1), isTrue);
    expect(c.isItalicAt(0), isFalse);
    expect(c.allConsonantsItalic, isFalse);
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    c.toggleSelectedItalics();
    expect(c.allConsonantsItalic, isTrue);
    c.toggleSelectedItalics();
    expect(c.allConsonantsItalic, isFalse);
    expect(c.text, 'David');
  });

  test(
    'formatting survives insertions and deletions; new letters stay plain',
    () {
      final c = PasswordController()..text = 'David';
      addTearDown(c.dispose);
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      c.toggleSelectedItalics();
      c.selection = const TextSelection.collapsed(offset: 0);
      c.replaceSelection('x');
      expect(c.isItalicAt(0), isFalse);
      expect(c.isItalicAt(1), isTrue);
      expect(c.allConsonantsItalic, isFalse);
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 1);
      c.replaceSelection('');
      expect(c.allConsonantsItalic, isTrue);
      c.selection = const TextSelection.collapsed(offset: 2);
      c.appendCat();
      expect(c.text, 'David😹');
      expect(c.selection.start, 2);
      expect(c.allConsonantsItalic, isTrue);
    },
  );

  test(
    'editing repeated letters preserves the correct character formatting',
    () {
      final c = PasswordController()..text = 'bbb';
      addTearDown(c.dispose);
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 1);
      c.toggleSelectedItalics();
      c.value = const TextEditingValue(
        text: 'bb',
        selection: TextSelection.collapsed(offset: 0),
      );
      expect(c.isItalicAt(0), isFalse);
      c.selection = const TextSelection(baseOffset: 1, extentOffset: 2);
      c.toggleSelectedItalics();
      c.selection = const TextSelection.collapsed(offset: 0);
      c.value = const TextEditingValue(
        text: 'bbb',
        selection: TextSelection.collapsed(offset: 1),
      );
      expect(c.isItalicAt(0), isFalse);
      expect(c.isItalicAt(2), isTrue);
    },
  );

  test('backspace removes a whole emoji then adds exactly one prefix', () {
    final c = PasswordController(random: Random(1))..text = 'David👨‍👩‍👧‍👦';
    addTearDown(c.dispose);
    c.selection = TextSelection.collapsed(offset: c.text.length);
    c.disruptiveBackspace();
    expect(c.text.characters.length, 6);
    expect(c.text.substring(1), 'David');
    expect(c.selection.start, 6);
    c.selection = const TextSelection.collapsed(offset: 0);
    c.disruptiveBackspace();
    expect(c.text.characters.length, 7);
  });

  test('soft backspace triggers once; forward delete and cats do not', () {
    final c = PasswordController(random: Random(2))..text = 'abcd';
    addTearDown(c.dispose);
    c.backspaceChaosEnabled = true;
    c.selection = const TextSelection.collapsed(offset: 4);
    c.value = const TextEditingValue(
      text: 'abc',
      selection: TextSelection.collapsed(offset: 3),
    );
    expect(c.text.length, 4);
    expect(c.text.substring(1), 'abc');
    c.selection = const TextSelection.collapsed(offset: 1);
    c.value = TextEditingValue(
      text: c.text.replaceRange(1, 2, ''),
      selection: const TextSelection.collapsed(offset: 1),
    );
    expect(c.text.length, 3);
    c.appendCat();
    expect(c.text.characters.length, 4);
  });
}
