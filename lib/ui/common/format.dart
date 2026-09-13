/// 340KB, 850MB, 1.2GB처럼 읽기 쉬운 파일 크기.
String formatBytes(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)}GB';
  if (bytes >= mb) return '${(bytes / mb).round()}MB';
  if (bytes >= kb) return '${(bytes / kb).round()}KB';
  return '${bytes}B';
}

/// 1:05, 12:30, 1:02:03처럼 재생 시간.
String formatDuration(Duration d) {
  String two(int v) => v.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}
