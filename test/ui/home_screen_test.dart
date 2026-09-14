import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/home/home_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('앱을 켜면 대본 탭에서 모든 대본이 바로 보이고, 모음 탭에서 폴더를 관리한다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      final audition = await h.services.repo.createCollection('1차 오디션');
      await h.services.repo.create(ScriptDraft(work: '햄릿', body: 'x', collectionIds: [audition]));
      await h.services.repo.create(const ScriptDraft(work: '갈매기', body: 'x'));
    });
    await tester.pumpWidget(h.wrap(const HomeScreen()));
    await tester.pumpAndSettle();

    // 대본 탭: 전체로 들어가지 않아도 대본이 보인다
    expect(find.text('모노로그'), findsOneWidget);
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsOneWidget);
    expect(find.text('새 모음'), findsNothing);

    await tester.tap(find.widgetWithText(NavigationDestination, '모음'));
    await tester.pumpAndSettle();
    expect(find.text('1차 오디션'), findsOneWidget);
    expect(find.text('새 모음'), findsOneWidget);
    expect(find.text('갈매기'), findsNothing);

    // 모음 탭에서 뒤로 가면 앱을 닫지 않고 대본 탭으로 돌아온다
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('갈매기'), findsOneWidget);
    expect(find.text('새 모음'), findsNothing);

    // 모음을 누르면 그 모음의 대본만 보인다
    await tester.tap(find.widgetWithText(NavigationDestination, '모음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1차 오디션'));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsNothing);
    await tester.runAsync(h.db.close);
  });
}
