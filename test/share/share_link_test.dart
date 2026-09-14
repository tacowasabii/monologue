import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/share/share_link.dart';

void main() {
  final id = 'Ab3_-${'x' * 17}';

  test('웹 링크와 앱 전용 주소에서 ID를 꺼낸다', () {
    expect(shareIdFromUri(Uri.parse('https://monologue.ink/s/$id')), id);
    expect(shareIdFromUri(Uri.parse('https://monologue.ink/s/$id/')), id);
    expect(shareIdFromUri(Uri.parse('monologue://s/$id')), id);
  });

  test('다른 주소나 모양이 다른 ID는 무시한다', () {
    expect(shareIdFromUri(Uri.parse('http://monologue.ink/s/$id')), isNull);
    expect(shareIdFromUri(Uri.parse('https://example.com/s/$id')), isNull);
    expect(shareIdFromUri(Uri.parse('https://tacowasabii.vercel.app/monologue/s/$id')), isNull);
    expect(shareIdFromUri(Uri.parse('https://monologue.ink/s/short')), isNull);
    expect(shareIdFromUri(Uri.parse('https://monologue.ink/privacy')), isNull);
    expect(shareIdFromUri(Uri.parse('https://monologue.ink/s/$id/extra')), isNull);
    expect(shareIdFromUri(Uri.parse('monologue://other/$id')), isNull);
  });

  test('API 주소', () {
    expect(shareApiBase.toString(), 'https://monologue.ink/api/shares');
  });
}
