import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ui/common/format.dart';

void main() {
  test('formatBytes는 읽기 쉬운 단위로 줄인다', () {
    expect(formatBytes(512), '512B');
    expect(formatBytes(340 * 1024), '340KB');
    expect(formatBytes(850 * 1024 * 1024), '850MB');
    expect(formatBytes((1.2 * 1024 * 1024 * 1024).round()), '1.2GB');
  });

  test('formatDuration은 분:초, 한 시간이 넘으면 시:분:초', () {
    expect(formatDuration(const Duration(seconds: 5)), '0:05');
    expect(formatDuration(const Duration(seconds: 65)), '1:05');
    expect(formatDuration(const Duration(minutes: 12, seconds: 30)), '12:30');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });
}
