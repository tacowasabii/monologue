import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monologue/app_scope.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

/// 공유 안내처럼 [keepWords]로 줄바꿈 금지 문자가 섞인 글은 일반 textContaining으로 못 찾으므로 걷어 내고 비교한다.
Finder findTextContaining(String substring) => find.byWidgetPredicate(
      (widget) => widget is Text && withoutWordJoiners(widget.data ?? '').contains(substring),
    );

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
          'url': 'https://monologue.ink/s/$id',
          'deleteToken': 'secret',
          'expiresAt': DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String(),
        }, 201);

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(findTextContaining('7일 동안 저장'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('연기 노트도 함께 보낼까요?'), findsOneWidget);
    await tester.tap(find.text('연기 노트 빼고 보내기'));
    await tester.pumpAndSettle();

    final body = jsonDecode(h.shareServer.requests.single.body) as Map<String, Object?>;
    expect(body['work'], '갈매기');
    expect(body['note'], isNull);
    expect(body.containsKey('memo'), isFalse);
    expect(h.services.shareHistory.noticeSeen, isTrue);
    expect(h.services.shareHistory.sent.single.id, id);
    final text = (shareCalls.single.arguments as Map)['text'] as String;
    expect(text, '「갈매기」 대본을 보냈어요\nhttps://monologue.ink/s/$id');
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

    expect(find.text('연기 노트도 함께 보낼까요?'), findsNothing);
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

  testWidgets('안내에서 취소하면 아무 요청도 보내지 않고 안내를 본 것으로 기억하지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final scriptId = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: '대사'))))!;

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(findTextContaining('7일 동안 저장'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(h.shareServer.requests, isEmpty);
    expect(h.services.shareHistory.noticeSeen, isFalse);
    await tester.runAsync(h.db.close);
  });

  testWidgets('노트 포함 여부를 취소하면 아무 요청도 보내지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(h.services.shareHistory.markNoticeSeen);
    final scriptId = (await tester.runAsync(
      () => h.services.repo.create(const ScriptDraft(work: '갈매기', body: '나는 갈매기', note: '호숫가')),
    ))!;

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.text('연기 노트도 함께 보낼까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(h.shareServer.requests, isEmpty);
    await tester.runAsync(h.db.close);
  });

  testWidgets('함께 보내기를 고르면 노트를 그대로 보낸다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(h.services.shareHistory.markNoticeSeen);
    final scriptId = (await tester.runAsync(
      () => h.services.repo.create(const ScriptDraft(work: '갈매기', body: '나는 갈매기', note: '호숫가')),
    ))!;
    h.shareServer.handler = (_) => jsonResponse({
          'id': id,
          'url': 'https://monologue.ink/s/$id',
          'deleteToken': 'secret',
          'expiresAt': DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String(),
        }, 201);

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.text('연기 노트도 함께 보낼까요?'), findsOneWidget);
    await tester.tap(find.text('함께 보내기'));
    await tester.pumpAndSettle();

    final body = jsonDecode(h.shareServer.requests.single.body) as Map<String, Object?>;
    expect(body['note'], '호숫가');
    await tester.runAsync(h.db.close);
  });

  testWidgets('너무 자주 보내면 잠시 뒤 다시 시도하라고 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(h.services.shareHistory.markNoticeSeen);
    final scriptId = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: '대사'))))!;
    h.shareServer.handler = (_) => http.Response('', 429);

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.text('잠시 뒤 다시 시도해 주세요'), findsOneWidget);
    expect(h.services.shareHistory.sent, isEmpty);
    await tester.runAsync(h.db.close);
  });

  testWidgets('링크는 만들었지만 공유 시트를 열지 못하면 알려 주고, 링크는 기록에 남는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(h.services.shareHistory.markNoticeSeen);
    final scriptId = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: '대사'))))!;
    h.shareServer.handler = (_) => jsonResponse({
          'id': id,
          'url': 'https://monologue.ink/s/$id',
          'deleteToken': 'secret',
          'expiresAt': DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String(),
        }, 201);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, (call) async {
      shareCalls.add(call);
      throw PlatformException(code: 'x');
    });

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: scriptId)));
    await tester.pumpAndSettle();
    await openShareMenu(tester);

    expect(find.text('공유 화면을 열지 못했어요'), findsOneWidget);
    expect(h.services.shareHistory.sent.single.id, id);
    await tester.runAsync(h.db.close);
  });

  testWidgets('업로드 중 다른 화면이 열려도 스피너 라우트만 지우고 새 화면은 남긴다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(h.services.shareHistory.markNoticeSeen);
    final scriptId = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: '대사'))))!;
    h.shareServer.handler = (_) => jsonResponse({
          'id': id,
          'url': 'https://monologue.ink/s/$id',
          'deleteToken': 'secret',
          'expiresAt': DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String(),
        }, 201);
    final completer = Completer<void>();
    h.shareServer.beforeRespond = (_) => completer.future;

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(AppScope(
      services: h.services,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ScriptViewScreen(scriptId: scriptId),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('링크로 공유'));
    // 스피너가 계속 도는 동안은 pumpAndSettle이 정착하지 않으므로(무한 애니메이션), 정해진 만큼만 민다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // IncomingLinks가 업로드 도중 공유 링크를 열어 새 화면을 쌓는 상황을 흉내 낸다
    navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('열린 링크 화면'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('열린 링크 화면'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('열린 링크 화면'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
