import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/home/home_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('앱을 켜면 대본 탭에서 모든 대본이 바로 보이고, 모음 탭에서 폴더를 관리한다', (tester) async {
    // 기본 테스트 화면(800×600)에서는 모음 카드 둘째 줄이 아래 탭에 가려진다. 실제 폰 크기로 맞춘다
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
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

  testWidgets(
    '아이폰에서는 아래 탭을 낮춰 홈 인디케이터 위가 크게 비지 않게 한다',
    (tester) async {
      final h = (await tester.runAsync(Harness.create))!;
      await tester.pumpWidget(h.wrap(const HomeScreen()));
      await tester.pumpAndSettle();
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.height, defaultTargetPlatform == TargetPlatform.iOS ? 60 : isNull);
      await tester.runAsync(h.db.close);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.android}),
  );
}
