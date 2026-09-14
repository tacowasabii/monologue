import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monologue/app.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/share/share_link.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/share/received_script_screen.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

void main() {
  final id = 'B' * 22;

  Map<String, Object?> hamlet() => {
        'v': 1,
        'work': '햄릿',
        'dialogue': false,
        'body': '사느냐 죽느냐',
        'gender': 'male',
        'ageRange': 'twenties',
        'tags': ['고전'],
        'note': '고뇌하는 왕자',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String(),
      };

  testWidgets('받은 대본을 보여 주고, 추가하면 내 대본이 되며, 같은 링크는 이미 추가했다고 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    h.shareServer.handler = (_) => jsonResponse(hamlet(), 200);

    await tester.pumpWidget(h.wrap(ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('햄릿')), findsOneWidget);
    expect(find.text(keepWords('사느냐 죽느냐')), findsOneWidget);
    expect(find.text(keepWords('고뇌하는 왕자')), findsOneWidget);
    expect(find.text('#고전'), findsOneWidget);
    expect(find.textContaining('일 뒤 링크가 사라져요'), findsOneWidget);

    await tester.tap(find.text('내 대본에 추가'));
    await tester.pumpAndSettle();
    expect(find.byType(ScriptViewScreen), findsOneWidget);
    final count = await tester.runAsync(() => h.services.repo.watchScriptCount().first);
    expect(count, 1);

    // 앞 화면에서 이동한 기록이 남지 않게 앱을 새로 만든다
    await tester.pumpWidget(KeyedSubtree(key: UniqueKey(), child: h.wrap(ReceivedScriptScreen(shareId: id))));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('이미 추가한 대본이에요')), findsOneWidget);
    expect(h.shareServer.requests, hasLength(1));
    await tester.runAsync(h.db.close);
  });

  testWidgets('내 대본에 추가하다가 실패하면 다시 시도할 수 있게 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    h.shareServer.handler = (_) => jsonResponse(hamlet(), 200);

    await tester.pumpWidget(h.wrap(ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('사느냐 죽느냐')), findsOneWidget);

    // db.close()는 이 하네스에서 다음 쿼리 때 조용히 새 메모리 DB를 여는 것으로 보여(계속 성공),
    // 대신 표를 지워서 repo.create의 insert가 실제로 실패하게 만든다
    await tester.runAsync(() => h.db.customStatement('DROP TABLE scripts'));

    await tester.tap(find.text('내 대본에 추가'));
    // pumpAndSettle이면 SnackBar가 뜨고 사라지는 것까지 시간이 흘러가 버려서, 뜬 직후만 확인한다
    await tester.pump();
    await tester.pump();
    expect(find.text('추가하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.byType(ScriptViewScreen), findsNothing);
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, '내 대본에 추가')).onPressed,
      isNotNull,
    );
    await tester.runAsync(h.db.close);
  });

  testWidgets('만료된 링크와 연결 실패를 구분해 알려 주고, 다시 시도할 수 있다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    h.shareServer.handler = (_) => http.Response('', 404);
    await tester.pumpWidget(h.wrap(ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('7일이 지나 사라졌거나 보낸 사람이 지운 링크예요')), findsOneWidget);
    expect(find.text('내 대본에 추가'), findsNothing);

    h.shareServer.handler = (_) => http.Response('', 503);
    // 앞 화면에서 이동한 기록이 남지 않게 앱을 새로 만든다
    await tester.pumpWidget(KeyedSubtree(key: UniqueKey(), child: h.wrap(ReceivedScriptScreen(shareId: id))));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('인터넷 연결을 확인해 주세요')), findsOneWidget);

    h.shareServer.handler = (_) => jsonResponse(hamlet(), 200);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('사느냐 죽느냐')), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('앱이 공유 링크를 받으면 받은 대본 화면을 열고, 다른 링크는 무시한다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    // 처음 켤 때 나오는 사용 방법은 넘긴 상태로 시작한다
    await tester.runAsync(h.services.tips.markOnboardingSeen);
    await tester.pumpWidget(AppScope(services: h.services, child: const MonologueApp()));
    await tester.pumpAndSettle();

    h.links.open(Uri.parse('https://tacowasabii.vercel.app/monologue/privacy'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceivedScriptScreen), findsNothing);

    h.links.open(Uri.parse('monologue://s/$id'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceivedScriptScreen), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('겹쳐 열린 두 받은 대본 화면에서 각각 추가해도 대본은 하나만 생긴다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    h.shareServer.handler = (_) => jsonResponse(hamlet(), 200);

    // 같은 링크를 두 번 열어 화면이 겹쳐 쌓인 상황(아래 화면은 위 화면에서 추가하기 전 상태를 그대로 들고 있다)
    await tester.pumpWidget(h.wrap(ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(builder: (_) => ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();
    expect(find.text('내 대본에 추가'), findsOneWidget);

    // 위 화면(나중에 연 화면)에서 먼저 추가한다
    await tester.tap(find.text('내 대본에 추가'));
    await tester.pumpAndSettle();
    expect(find.byType(ScriptViewScreen), findsOneWidget);
    var count = await tester.runAsync(() => h.services.repo.watchScriptCount().first);
    expect(count, 1);

    // 아래 깔려 있던 화면(아직 옛 상태)으로 돌아가 다시 추가를 눌러도 대본이 하나 더 생기면 안 된다
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('내 대본에 추가'), findsOneWidget);
    await tester.tap(find.text('내 대본에 추가'));
    await tester.pumpAndSettle();
    expect(find.byType(ScriptViewScreen), findsOneWidget);

    count = await tester.runAsync(() => h.services.repo.watchScriptCount().first);
    expect(count, 1);
    // 화면 두 개가 각자 미리보기를 받아 왔지만(GET 두 번) 추가는 하나로 합쳐진다
    expect(h.shareServer.requests, hasLength(2));
    await tester.runAsync(h.db.close);
  });

  testWidgets('다시 시도를 누르면 새로 받아오는 동안 진행 표시를 보여 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    h.shareServer.handler = (_) => http.Response('', 503);

    await tester.pumpWidget(h.wrap(ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();
    expect(find.text(keepWords('인터넷 연결을 확인해 주세요')), findsOneWidget);

    final completer = Completer<void>();
    h.shareServer.handler = (_) => jsonResponse(hamlet(), 200);
    h.shareServer.beforeRespond = (_) => completer.future;

    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.text(keepWords('사느냐 죽느냐')), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('불러오다 예외가 나도 앱이 죽지 않고 다시 시도 화면을 보여 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    // shareHistory에는 이미 추가한 것으로 남아 있지만(예: 백업 복원 등으로) repo 조회 자체가 실패하는 상황을 흉내 낸다
    await tester.runAsync(() => h.services.shareHistory.markReceived(id, 1));
    await tester.runAsync(() => h.db.customStatement('DROP TABLE scripts'));

    await tester.pumpWidget(h.wrap(ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(keepWords('인터넷 연결을 확인해 주세요')), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('받은 대본 아래에 문제를 알릴 수 있는 안내가 보인다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    h.shareServer.handler = (_) => jsonResponse(hamlet(), 200);

    await tester.pumpWidget(h.wrap(ReceivedScriptScreen(shareId: id)));
    await tester.pumpAndSettle();

    expect(find.text(keepWords('문제가 있는 대본은 $shareReportEmail으로 알려 주세요')), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
