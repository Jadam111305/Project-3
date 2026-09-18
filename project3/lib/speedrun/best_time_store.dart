import 'package:shared_preferences/shared_preferences.dart';

/// Persists the shortest completed Speedrun Mode time in milliseconds.
class BestTimeStore {
  static const _bestTimeKey = 'speedrun_best_time_milliseconds';

  Future<Duration?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final milliseconds = preferences.getInt(_bestTimeKey);
    return milliseconds == null ? null : Duration(milliseconds: milliseconds);
  }

  /// Saves [time] only when it improves on the current personal best.
  Future<bool> saveIfFaster(Duration time) async {
    final preferences = await SharedPreferences.getInstance();
    final previous = preferences.getInt(_bestTimeKey);
    if (previous != null && previous <= time.inMilliseconds) return false;

    await preferences.setInt(_bestTimeKey, time.inMilliseconds);
    return true;
  }
}
