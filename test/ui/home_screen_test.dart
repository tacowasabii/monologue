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
    '아이폰에서는 홈 인디케이터 여백 일부를 탭 안쪽으로 옮겨, 탭은 낮추고 아이콘은 아래로 내린다',
    (tester) async {
      // 다이내믹 아일랜드와 홈 인디케이터가 있는 아이폰(iPhone 17 Pro): 위 여백 62pt, 아래 여백 34pt.
      // 위 여백을 넣어 두어야 상태 표시줄 여백이 탭에 붙는 실수를 잡는다
      tester.view.physicalSize = const Size(1206, 2622);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 62 * 3.0, bottom: 34 * 3.0);
      addTearDown(tester.view.reset);
      final h = (await tester.runAsync(Harness.create))!;
      await tester.pumpWidget(h.wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      final ios = defaultTargetPlatform == TargetPlatform.iOS;
      final bar = find.byType(NavigationBar);
      expect(tester.widget<NavigationBar>(bar).height, ios ? 84 : isNull);
      // 여백까지 합친 탭 전체 높이: 아이폰 60 + 34, 안드로이드 기본 80 + 34
      expect(tester.getSize(bar).height, ios ? 94 : 114);
      final iconTop = tester.getTopLeft(find.byIcon(Icons.folder_outlined)).dy - tester.getTopLeft(bar).dy;
      expect(iconTop, ios ? greaterThan(18) : greaterThan(0));
      await tester.runAsync(h.db.close);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.android}),
  );
}
