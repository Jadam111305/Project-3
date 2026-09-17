import 'dart:math';

import 'package:flutter/material.dart';

import 'password_rules.dart';

/// Stores formatting separately, indexed by the editor's UTF-16 offsets.
/// New text is plain; surviving text retains formatting after insert/delete.
class PasswordController extends TextEditingController {
  PasswordController({Random? random}) : _random = random ?? Random();
  final Random _random;
  List<bool> _italics = [];
  bool backspaceChaosEnabled = false;

  bool get hasSelection => selection.isValid && !selection.isCollapsed;
  bool get selectionIsItalic =>
      hasSelection &&
      _italics.sublist(selection.start, selection.end).every((v) => v);
  bool isItalicAt(int offset) =>
      offset >= 0 && offset < _italics.length && _italics[offset];
  bool get allConsonantsItalic {
    final matches = consonants.allMatches(text).toList();
    return matches.isNotEmpty && matches.every((m) => isItalicAt(m.start));
  }

  void toggleSelectedItalics() {
    if (!hasSelection) return;
    final makeItalic = !selectionIsItalic;
    for (var i = selection.start; i < selection.end; i++) {
      _italics[i] = makeItalic;
    }
    notifyListeners();
  }

  @override
  set value(TextEditingValue next) {
    final old = super.value;
    if (old.text == next.text) {
      super.value = next;
      return;
    }
    var start = 0;
    while (start < old.text.length &&
        start < next.text.length &&
        old.text.codeUnitAt(start) == next.text.codeUnitAt(start)) {
      start++;
    }
    var oldEnd = old.text.length;
    var newEnd = next.text.length;
    while (oldEnd > start &&
        newEnd > start &&
        old.text.codeUnitAt(oldEnd - 1) == next.text.codeUnitAt(newEnd - 1)) {
      oldEnd--;
      newEnd--;
    }

    // Prefer the actual edit selection when identical adjacent letters would
    // make a longest-prefix diff ambiguous.
    final s = old.selection;
    if (s.isValid) {
      var candidateStart = s.start;
      final candidateEnd = s.end;
      final delta = next.text.length - old.text.length;
      if (s.isCollapsed &&
          delta < 0 &&
          next.selection.isValid &&
          next.selection.start < s.start) {
        candidateStart = s.start + delta;
      }
      final inserted =
          next.text.length -
          (old.text.length - (candidateEnd - candidateStart));
      if (candidateStart >= 0 &&
          inserted >= 0 &&
          next.text.startsWith(old.text.substring(0, candidateStart)) &&
          next.text.endsWith(old.text.substring(candidateEnd))) {
        start = candidateStart;
        oldEnd = candidateEnd;
        newEnd = candidateStart + inserted;
      }
    }
    _italics = [
      ..._italics.take(start),
      ...List.filled(newEnd - start, false),
      ..._italics.skip(oldEnd),
    ];

    // Soft keyboards deliver backward deletion as an editing value instead
    // of a key event. Programmatic cat/emoji insertions bypass this setter.
    final softBackspace =
        backspaceChaosEnabled &&
        s.isValid &&
        s.isCollapsed &&
        next.selection.isValid &&
        next.selection.isCollapsed &&
        next.selection.start < s.start &&
        old.text.length > next.text.length &&
        newEnd == start;
    if (softBackspace) {
      _italics.insert(0, false);
      next = next.copyWith(
        text: _randomCharacter() + next.text,
        selection: TextSelection.collapsed(offset: next.selection.start + 1),
        composing: TextRange.empty,
      );
    }
    super.value = next;
  }

  String _randomCharacter() {
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return alphabet[_random.nextInt(alphabet.length)];
  }

  void replaceSelection(String replacement) {
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    _replace(start, end, replacement, moveCaret: true);
  }

  void appendCat() => _replace(text.length, text.length, '😹');

  void disruptiveBackspace() {
    if (!selection.isValid) return;
    var start = selection.start;
    final end = selection.end;
    if (selection.isCollapsed && start > 0) {
      start -= text.substring(0, start).characters.last.length;
    }
    // One prefix for each physical press, including at the start of the text.
    final remainder = text.replaceRange(start, end, '');
    _italics = [false, ..._italics.take(start), ..._italics.skip(end)];
    super.value = TextEditingValue(
      text: _randomCharacter() + remainder,
      selection: TextSelection.collapsed(offset: start + 1),
    );
  }

  void _replace(
    int start,
    int end,
    String replacement, {
    bool moveCaret = false,
  }) {
    final old = value;
    final delta = replacement.length - (end - start);
    int shift(int offset) => offset < 0
        ? offset
        : offset <= start
        ? offset
        : offset >= end
        ? offset + delta
        : start + replacement.length;
    _italics = [
      ..._italics.take(start),
      ...List.filled(replacement.length, false),
      ..._italics.skip(end),
    ];
    super.value = old.copyWith(
      text: old.text.replaceRange(start, end, replacement),
      selection: moveCaret
          ? TextSelection.collapsed(offset: start + replacement.length)
          : TextSelection(
              baseOffset: shift(old.selection.baseOffset),
              extentOffset: shift(old.selection.extentOffset),
            ),
      composing: old.composing.isValid && !moveCaret
          ? TextRange(
              start: shift(old.composing.start),
              end: shift(old.composing.end),
            )
          : TextRange.empty,
    );
  }

  @override
  void clear() {
    _italics = [];
    super.value = const TextEditingValue(
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    var offset = 0;
    return TextSpan(
      style: style,
      children: text.characters.map((character) {
        final start = offset;
        offset += character.length;
        final composing =
            withComposing &&
            value.isComposingRangeValid &&
            start < value.composing.end &&
            offset > value.composing.start;
        return TextSpan(
          text: character,
          style: TextStyle(
            fontStyle: isItalicAt(start) ? FontStyle.italic : FontStyle.normal,
            decoration: composing ? TextDecoration.underline : null,
          ),
        );
      }).toList(),
    );
  }
}
