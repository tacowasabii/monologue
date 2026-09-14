import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monologue/share/sent_link.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/share/sent_links_screen.dart';

import 'test_harness.dart';

void main() {
  final id = 'C' * 22;
  SentLink hamlet() => SentLink(
        id: id,
        url: 'https://tacowasabii.vercel.app/monologue/s/$id',
        deleteToken: 'secret',
        title: '햄릿',
        expiresAt: DateTime.now().add(const Duration(days: 3)),
      );

  testWidgets('보낸 링크를 남은 기간과 함께 보여 주고, 복사할 수 있다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() => h.services.shareHistory.addSent(hamlet()));
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(h.wrap(const SentLinksScreen()));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('3일 뒤 사라져요'), findsOneWidget);

    await tester.tap(find.byTooltip('링크 복사'));
    await tester.pumpAndSettle();
    expect(copied, 'https://tacowasabii.vercel.app/monologue/s/$id');
    expect(find.text('링크를 복사했어요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('지우면 서버에서 지우고 목록에서도 빼며, 실패하면 남겨 둔다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() => h.services.shareHistory.addSent(hamlet()));
    await tester.pumpWidget(h.wrap(const SentLinksScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('지우기'));
    await tester.pumpAndSettle();
    expect(find.text('이 링크를 지울까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '지우기'));
    await tester.pumpAndSettle();
    expect(find.text('지우지 못했어요. 인터넷 연결을 확인해 주세요'), findsOneWidget);
    expect(find.text('햄릿'), findsOneWidget);

    h.shareServer.handler = (_) => http.Response('', 204);
    await tester.tap(find.byTooltip('지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '지우기'));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('7일 안에 보낸 링크가 없어요')), findsOneWidget);
    expect(h.shareServer.requests.last.method, 'DELETE');
    expect(h.shareServer.requests.last.headers['Authorization'], 'Bearer secret');
    expect(h.services.shareHistory.sent, isEmpty);
    await tester.runAsync(h.db.close);
  });
}
