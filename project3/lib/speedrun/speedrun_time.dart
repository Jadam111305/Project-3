/// Formats elapsed time as `minutes:seconds:centiseconds`.
String formatSpeedrunTime(Duration time) {
  final minutes = time.inMinutes.remainder(100).toString().padLeft(2, '0');
  final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
  final centiseconds = (time.inMilliseconds.remainder(1000) ~/ 10)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds:$centiseconds';
}
