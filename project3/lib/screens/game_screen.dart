import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../password_controller.dart';
import '../password_rules.dart';
import '../speedrun/best_time_store.dart';
import '../speedrun/speedrun_time.dart';
import '../weather_service.dart';
import 'weather_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.createGame,
    this.weatherService,
    this.random,
    this.speedrun = false,
    this.bestTimeStore,
  });
  final PasswordGame Function()? createGame;
  final WeatherService? weatherService;
  final Random? random;
  final bool speedrun;
  final BestTimeStore? bestTimeStore;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Color get _brown =>
      _mystery ? const Color(0xFFF1E2CB) : const Color(0xFF533827);
  Color get _cream =>
      _mystery ? const Color(0xFF25212B) : const Color(0xFFFFF8EC);
  Color get _muted =>
      _mystery ? const Color(0xFFD5C4DF) : const Color(0xFF755B46);
  late final PasswordController _controller;
  final _inputFocus = FocusNode();
  late final WeatherService _weather;
  late final Random _random;
  late PasswordGame _game;
  Timer? _revealTimer;
  Timer? _dateTimer;
  Timer? _catTimer;
  Timer? _mysteryTimer;
  Timer? _speedrunTimer;
  final Stopwatch _stopwatch = Stopwatch();
  bool _mystery = false;
  bool _finished = false;
  int _epoch = 0;
  late String _today;

  String get _password => _controller.text;
  bool get _italic => _controller.allConsonantsItalic;
  bool get _hasWon => _finished;

  @override
  void initState() {
    super.initState();
    _random = widget.random ?? Random();
    _controller = PasswordController(random: _random);
    _weather = widget.weatherService ?? WeatherService();
    _game = widget.createGame?.call() ?? PasswordGame();
    _today = _game.today;
    _dateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_finished && _today != _game.today) {
        _today = _game.today;
        _changed();
      }
    });
    _activateEffects();
    if (widget.speedrun) {
      _stopwatch.start();
      _speedrunTimer = Timer.periodic(
        const Duration(milliseconds: 10),
        (_) => mounted && !_finished ? setState(() {}) : null,
      );
    }
  }

  void _changed() {
    if (_finished) return;
    setState(() {
      if (_game.hasWon(_password, _italic)) {
        _stopwatch.stop();
        _speedrunTimer?.cancel();
        _finished = true;
        _mystery = false;
        _stopEffects();
        if (widget.speedrun) _saveBestTime();
      }
    });
    _scheduleReveal();
  }

  Future<void> _saveBestTime() async {
    await (widget.bestTimeStore ?? BestTimeStore()).saveIfFaster(
      _stopwatch.elapsed,
    );
  }

  void _activateEffects() {
    if (_finished) return;
    if (_game.isUnlocked('cats') && _catTimer == null) {
      // Started once at unlock, never reset by typing.
      _catTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || _finished) return;
        _controller.appendCat();
        _changed();
      });
    }
    if (_game.isUnlocked('mystery') && _mysteryTimer == null) {
      _scheduleMystery();
    }
    _controller.backspaceChaosEnabled = _game.isUnlocked('backspace');
  }

  void _scheduleMystery() {
    _mysteryTimer = Timer(Duration(seconds: 7 + _random.nextInt(8)), () {
      if (!mounted || _finished) return;
      setState(() => _mystery = !_mystery);
      _scheduleMystery();
    });
  }

  void _stopEffects() {
    _revealTimer?.cancel();
    _catTimer?.cancel();
    _catTimer = null;
    _mysteryTimer?.cancel();
    _mysteryTimer = null;
    _controller.backspaceChaosEnabled = false;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_finished &&
        _inputFocus.hasFocus &&
        _controller.backspaceChaosEnabled &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        (event is KeyDownEvent || event is KeyRepeatEvent) &&
        _controller.value.composing.isCollapsed) {
      _controller.disruptiveBackspace();
      _changed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _scheduleReveal() {
    _revealTimer?.cancel();
    if (_finished ||
        _game.visibleCount == _game.rules.length ||
        !_game.allVisiblePass(_password, _italic)) {
      return;
    }
    // Reveal one rule per animation, even if pasted text passes several rules.
    _revealTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || !_controller.value.composing.isCollapsed) return;
      if (_game.revealNext(_password, _italic)) {
        _activateEffects();
        _changed();
      }
    });
  }

  void _reset() {
    _stopEffects();
    _speedrunTimer?.cancel();
    _controller.clear();
    setState(() {
      _finished = false;
      _mystery = false;
      _epoch++;
      _game = widget.createGame?.call() ?? PasswordGame();
      _today = _game.today;
    });
    _activateEffects();
    if (widget.speedrun) {
      _stopwatch
        ..reset()
        ..start();
      _speedrunTimer = Timer.periodic(
        const Duration(milliseconds: 10),
        (_) => mounted && !_finished ? setState(() {}) : null,
      );
    }
  }

  void _insertEmoji(String emoji) {
    _controller.replaceSelection(emoji);
    _changed();
  }

  @override
  void dispose() {
    _stopEffects();
    _dateTimer?.cancel();
    _speedrunTimer?.cancel();
    _inputFocus.dispose();
    if (widget.weatherService == null) _weather.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passed = _game.passedCount(_password, _italic);
    final length = _password.characters.length;
    final total = _game.rules.length;
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF533827),
          brightness: _mystery ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      child: Transform.rotate(
        key: const ValueKey('mystery-rotation'),
        angle: _mystery ? pi : 0,
        child: Scaffold(
          backgroundColor: _mystery
              ? const Color(0xFF16131C)
              : const Color(0xFFF1E2CB),
          appBar: AppBar(
            title: const Text('PASSWORD GAME'),
            backgroundColor: _cream,
            foregroundColor: _brown,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.speedrun) ...[
                        _speedrunTimerCard(),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        _hasWon
                            ? 'Password accepted!'
                            : 'One password. Every rule.',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: _brown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasWon
                            ? 'You satisfied all $total rules. Chaos stopped!'
                            : 'Solve each new rule while keeping the earlier ones satisfied.',
                      ),
                      const SizedBox(height: 20),
                      Focus(
                        onKeyEvent: _onKey,
                        child: TextField(
                          key: const ValueKey('password-input'),
                          controller: _controller,
                          focusNode: _inputFocus,
                          readOnly: _finished,
                          minLines: 2,
                          maxLines: 5,
                          autocorrect: false,
                          enableSuggestions: false,
                          smartQuotesType: SmartQuotesType.disabled,
                          smartDashesType: SmartDashesType.disabled,
                          onChanged: (_) => _changed(),
                          decoration: InputDecoration(
                            labelText: 'Your game password',
                            hintText: 'Start typing…',
                            filled: true,
                            fillColor: _cream,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$length characters • $passed / $total rules satisfied',
                        key: const ValueKey('progress-label'),
                      ),
                      if (_game.visibleCount >= 11) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: ['😀', '🌟', '🐱', '🚀', '❤️']
                              .map(
                                (emoji) => ActionChip(
                                  label: Text(emoji),
                                  tooltip: 'Insert $emoji',
                                  onPressed: _finished
                                      ? null
                                      : () => _insertEmoji(emoji),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (_game.visibleCount >= 12)
                        Wrap(
                          children: [
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _controller,
                              builder: (context, value, _) =>
                                  OutlinedButton.icon(
                                    key: const ValueKey('italic-control'),
                                    icon: const Icon(Icons.format_italic),
                                    label: const Text(
                                      'Italic selected characters',
                                    ),
                                    onPressed:
                                        _finished || !_controller.hasSelection
                                        ? null
                                        : () {
                                            _controller.toggleSelectedItalics();
                                            _inputFocus.requestFocus();
                                            _changed();
                                          },
                                  ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: passed / _game.rules.length,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        color: _hasWon ? Colors.green.shade700 : _brown,
                        backgroundColor: const Color(0xFFD9C5A7),
                        semanticsLabel: '$passed of $total rules satisfied',
                      ),
                      const SizedBox(height: 20),
                      // Newest rule is nearest the input; earlier rules stay active.
                      for (
                        var index = _game.visibleCount - 1;
                        index >= 0;
                        index--
                      )
                        _ruleCard(index),
                      if (_hasWon)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: FilledButton.icon(
                            key: const ValueKey('play-again'),
                            onPressed: _reset,
                            icon: const Icon(Icons.replay),
                            label: const Text('PLAY AGAIN'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _speedrunTimerCard() {
    return Container(
      key: const ValueKey('speedrun-timer'),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC6AC88)),
      ),
      child: Column(
        children: [
          Text(
            _hasWon ? 'FINAL TIME' : 'SPEEDRUN TIME',
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatSpeedrunTime(_stopwatch.elapsed),
            key: const ValueKey('speedrun-time-value'),
            style: TextStyle(
              color: _brown,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleCard(int index) {
    final rule = _game.rules[index];
    final passed = _game.passes(index, _password, _italic);
    final number = index + 1;
    return TweenAnimationBuilder<double>(
      key: ValueKey('rule-${rule.id}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Semantics(
        label: 'Rule $number: ${passed ? 'passed' : 'not satisfied'}',
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: passed
                ? (_mystery ? const Color(0xFF1D3D2A) : const Color(0xFFE1F0DF))
                : _cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: passed ? const Color(0xFF3C7A48) : const Color(0xFFC6AC88),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    passed ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: passed ? const Color(0xFF3C7A48) : _brown,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RULE $number',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rule.description,
                style: TextStyle(
                  color: _brown,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (rule.detail != null) ...[
                const SizedBox(height: 8),
                Text(rule.detail!, style: TextStyle(color: _muted)),
              ],
              if (rule.id == 'temperature')
                IgnorePointer(
                  ignoring: _finished,
                  child: WeatherPanel(
                    key: ValueKey('weather-$_epoch'),
                    service: _weather,
                    onChanged: (snapshot) {
                      if (_finished) return;
                      _game.temperatureF = snapshot?.answer;
                      _changed();
                    },
                  ),
                ),
              if (rule.id == 'extensions') ...[
                const SizedBox(height: 8),
                Text(
                  'Found: ${fileExtensions(_password).isEmpty ? 'none yet' : fileExtensions(_password).map((e) => '.$e').join(', ')}',
                ),
              ],
              if (rule.id == 'date') ...[
                const SizedBox(height: 8),
                Text('Today: ${_game.today}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
