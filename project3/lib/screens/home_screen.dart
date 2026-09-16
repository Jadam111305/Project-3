import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF533827);
    const beige = Color(0xFFF1E2CB);

    return Scaffold(
      backgroundColor: beige,
      body: SafeArea(
        child: Center(
          // Allow scrolling on small screens or when text is enlarged.
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
                        // Navigation can be added when the game screen is ready.
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          foregroundColor: const Color(0xFFFFF8EC),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        child: const Text(
                          'START GAME',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
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
}
