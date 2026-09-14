import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:monologue/app.dart';
import 'package:monologue/app_scope.dart';
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
}
