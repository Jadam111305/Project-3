import 'package:flutter/material.dart';

import 'game_screen.dart';
import '../speedrun/best_time_store.dart';
import '../speedrun/speedrun_time.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.bestTimeStore});

  final BestTimeStore? bestTimeStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BestTimeStore _bestTimeStore;
  Duration? _bestTime;

  @override
  void initState() {
    super.initState();
    _bestTimeStore = widget.bestTimeStore ?? BestTimeStore();
    _loadBestTime();
  }

  Future<void> _loadBestTime() async {
    final bestTime = await _bestTimeStore.load();
    if (mounted) setState(() => _bestTime = bestTime);
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF533827);
    const beige = Color(0xFFF1E2CB);

    return Scaffold(
      backgroundColor: beige,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EC),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: brown, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFC6AC88), offset: Offset(0, 7)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: beige,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 32,
                        color: brown,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'A PASSWORD GAME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: brown,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Think you can make the perfect password?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: brown, fontSize: 18, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openGame(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          foregroundColor: const Color(0xFFFFF8EC),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        child: const Text('START GAME'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const ValueKey('speedrun-mode-button'),
                        onPressed: () => _openGame(context, speedrun: true),
                        icon: const Icon(Icons.timer_outlined),
                        label: const Text('SPEEDRUN MODE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brown,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: const BorderSide(color: brown, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    if (_bestTime != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        key: const ValueKey('speedrun-best-time'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: beige,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'SPEEDRUN BEST: ${formatSpeedrunTime(_bestTime!)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: brown,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Your goal is simple: create a password that follows every rule. Can you get them all right?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF755B46),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openGame(BuildContext context, {bool speedrun = false}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          speedrun: speedrun,
          bestTimeStore: speedrun ? _bestTimeStore : null,
        ),
      ),
    );
    if (speedrun) await _loadBestTime();
  }
}
