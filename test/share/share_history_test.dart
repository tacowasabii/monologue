import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/share/sent_link.dart';
import 'package:monologue/share/share_history.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

SentLink link(String id, DateTime expiresAt) =>
    SentLink(id: id, url: 'https://tacowasabii.vercel.app/monologue/s/$id', deleteToken: 't-$id', title: '대본 $id', expiresAt: expiresAt);

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('보낸 링크는 다시 불러와도 남고, 최근 것부터, 만료된 것은 빠진다', () async {
    var now = DateTime.utc(2026, 9, 14);
    final history = await ShareHistory.load(now: () => now);
    await history.addSent(link('a', DateTime.utc(2026, 9, 21)));
    await history.addSent(link('b', DateTime.utc(2026, 9, 15)));

    final reloaded = await ShareHistory.load(now: () => now);
    expect(reloaded.sent.map((l) => l.id), ['b', 'a']);
    expect(reloaded.sent.first.deleteToken, 't-b');

    now = DateTime.utc(2026, 9, 16);
    expect(reloaded.sent.map((l) => l.id), ['a']);

    await reloaded.removeSent('a');
    expect((await ShareHistory.load(now: () => now)).sent, isEmpty);
  });

  test('받은 링크로 만든 대본 id와 첫 공유 안내 확인을 기억한다', () async {
    final history = await ShareHistory.load();
    expect(history.receivedScriptId('x'), isNull);
    expect(history.noticeSeen, isFalse);

    await history.markReceived('x', 42);
    await history.markNoticeSeen();

    final reloaded = await ShareHistory.load();
    expect(reloaded.receivedScriptId('x'), 42);
    expect(reloaded.noticeSeen, isTrue);
  });
}
