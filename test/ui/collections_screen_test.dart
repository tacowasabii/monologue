import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/settings/home_view_settings.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/home/collections_screen.dart';

import 'test_harness.dart';

/// 기본 테스트 화면(800×600)은 카드가 커져 둘째 줄이 화면 밖에 걸린다. 실제 폰 크기로 맞춘다.
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Finder get nameField => find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));

void main() {
  testWidgets('첫 화면은 전체와 모음을 대본 수와 함께 보여 주고, 모음을 누르면 그 대본만 보인다', (tester) async {
    usePhoneSize(tester);
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      final repo = h.services.repo;
      final audition = await repo.createCollection('1차 오디션');
      await repo.createCollection('입시');
      await repo.create(ScriptDraft(work: '햄릿', body: 'x', collectionIds: [audition]));
      await repo.create(const ScriptDraft(work: '갈매기', body: 'x'));
    });
    await tester.pumpWidget(h.wrap(const CollectionsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('전체'), findsOneWidget);
    expect(find.text('2편'), findsOneWidget);
    expect(find.text('1차 오디션'), findsOneWidget);
    expect(find.text('1편'), findsOneWidget);
    expect(find.text('입시'), findsOneWidget);
    expect(find.text('0편'), findsOneWidget);

    await tester.tap(find.text('1차 오디션'));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsNothing);
    await tester.runAsync(h.db.close);
  });

  testWidgets('새 모음을 만들 수 있고, 이미 있는 이름은 막는다', (tester) async {
    usePhoneSize(tester);
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() => h.services.repo.createCollection('입시'));
    await tester.pumpWidget(h.wrap(const CollectionsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('새 모음'));
    await tester.pumpAndSettle();
    await tester.enterText(nameField, '입시');
    await tester.pump();
    expect(find.text('이미 있는 모음이에요'), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, '만들기')).onPressed, isNull);

    await tester.enterText(nameField, '1차 오디션');
    await tester.pump();
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    expect(find.text('1차 오디션'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('모음을 길게 눌러 지워도 대본은 남는다', (tester) async {
    usePhoneSize(tester);
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      final audition = await h.services.repo.createCollection('1차 오디션');
      await h.services.repo.create(ScriptDraft(work: '햄릿', body: 'x', collectionIds: [audition]));
    });
    await tester.pumpWidget(h.wrap(const CollectionsScreen()));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('1차 오디션'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.textContaining(keepWords('대본은 그대로 남아요')), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();

    expect(find.text('1차 오디션'), findsNothing);
    expect(find.text('1편'), findsOneWidget); // 전체
    await tester.runAsync(h.db.close);
  });

  testWidgets('목록으로 바꾸면 같은 모음을 줄로 보여 주고, 고른 방식을 기억한다', (tester) async {
    usePhoneSize(tester);
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      final audition = await h.services.repo.createCollection('1차 오디션');
      await h.services.repo.create(ScriptDraft(work: '햄릿', body: 'x', collectionIds: [audition]));
    });
    await tester.pumpWidget(h.wrap(const CollectionsScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(SliverGrid), findsOneWidget);

    await tester.tap(find.byTooltip('목록으로 보기'));
    await tester.pumpAndSettle();
    expect(find.byType(SliverGrid), findsNothing);
    expect(find.widgetWithText(ListTile, '전체'), findsOneWidget);
    expect(find.widgetWithText(ListTile, '1차 오디션'), findsOneWidget);
    expect(find.widgetWithText(ListTile, '새 모음'), findsOneWidget);
    expect(find.text('1편'), findsNWidgets(2)); // 전체, 1차 오디션
    expect(h.services.homeView.layout, HomeLayout.list);

    await tester.tap(find.widgetWithText(ListTile, '1차 오디션'));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
