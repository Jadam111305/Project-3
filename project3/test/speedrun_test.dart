import 'package:flutter_test/flutter_test.dart';
import 'package:project3/speedrun/best_time_store.dart';
import 'package:project3/speedrun/speedrun_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('formats a speedrun duration as minutes, seconds, and centiseconds', () {
    expect(
      formatSpeedrunTime(
        const Duration(minutes: 2, seconds: 7, milliseconds: 430),
      ),
      '02:07:43',
    );
  });

  test('keeps only the fastest persisted speedrun time', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BestTimeStore();

    expect(
      await store.saveIfFaster(const Duration(milliseconds: 1500)),
      isTrue,
    );
    expect(
      await store.saveIfFaster(const Duration(milliseconds: 1800)),
      isFalse,
    );
    expect(
      await store.saveIfFaster(const Duration(milliseconds: 1200)),
      isTrue,
    );
    expect(await store.load(), const Duration(milliseconds: 1200));
  });
}
