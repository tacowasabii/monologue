import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  late List<MethodCall> shareCalls;

  setUp(() {
    shareCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, (call) async {
      shareCalls.add(call);
      return 'dev.fluttercommunity.plus/share/success';
    });
  });

  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, null));

  final id = 'A' * 22;

  Future<void> openShareMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('링크로 공유'));
    await tester.pumpAndSettle();
  }

  testWidgets('처음 공유하면 안내를 보여 주고, 노트를 뺄지 고른 뒤 링크를 만들어 공유 시트에 넘긴다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final scriptId = (await tester.runAsync(
      () => h.services.repo.create(const ScriptDraft(work: '갈매기', memo: '비공개 메모', body: '나는 갈매기', note: '호숫가')),
    ))!;
    h.shareServer.handler = (_) => jsonResponse({
          'id': id,
          'url': 'https://tacowasabii.vercel.app/monologue/s/$id',
          'deleteToken': 'secret',
          'expiresAt': DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String(),
        }, 201);

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.textContaining('7일 동안 저장'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('노트도 함께 보낼까요?'), findsOneWidget);
    await tester.tap(find.text('노트 빼고 보내기'));
    await tester.pumpAndSettle();

    final body = jsonDecode(h.shareServer.requests.single.body) as Map<String, Object?>;
    expect(body['work'], '갈매기');
    expect(body['note'], isNull);
    expect(body.containsKey('memo'), isFalse);
    expect(h.services.shareHistory.noticeSeen, isTrue);
    expect(h.services.shareHistory.sent.single.id, id);
    final text = (shareCalls.single.arguments as Map)['text'] as String;
    expect(text, '「갈매기」 대본을 보냈어요\nhttps://tacowasabii.vercel.app/monologue/s/$id');
    await tester.runAsync(h.db.close);
  });

  testWidgets('안내를 이미 봤고 노트가 없으면 바로 올리고, 너무 길면 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(h.services.shareHistory.markNoticeSeen);
    final scriptId = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(work: '긴 대본', body: '대사'))))!;
    h.shareServer.handler = (_) => http.Response('', 413);

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.text('노트도 함께 보낼까요?'), findsNothing);
    expect(find.text('대본이 너무 길어서 링크로 보낼 수 없어요'), findsOneWidget);
    expect(shareCalls, isEmpty);
    expect(h.services.shareHistory.sent, isEmpty);
    await tester.runAsync(h.db.close);
  });

  testWidgets('서버에 닿지 못하면 다시 시도하라고 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(h.services.shareHistory.markNoticeSeen);
    final scriptId = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: '대사'))))!;

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.text('지금 링크를 만들 수 없어요. 인터넷 연결을 확인하고 다시 시도해 주세요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
