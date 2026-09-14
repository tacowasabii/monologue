import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/common/adaptive.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/home/collections_screen.dart';
import 'package:monologue/ui/home/home_screen.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

/// 창 크기(논리 픽셀). 폴드는 갤럭시 Z 폴드4를 펼친 세로 화면, 아이패드는 11인치 아이패드 프로.
const phone = Size(360, 800);
const unfoldedFold = Size(673, 841);
const iPadPortrait = Size(834, 1210);
const iPadLandscape = Size(1210, 834);

const nothingOpen = '대본을 고르면 여기에 보여요';

void setWindow(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = size * 3.0;
  addTearDown(tester.view.reset);
}

Finder bodyText(String text) => find.byWidgetPredicate((w) => w is SelectableText && w.data == keepWords(text));

Finder railDestination(String label) => find.descendant(of: find.byType(NavigationRail), matching: find.text(label));

/// 파일 삭제 같은 실제 입출력이 끝나도록 실제 시간으로 기다렸다가 화면을 갱신한다.
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

Future<Harness> harnessWithScripts(WidgetTester tester) async {
  final h = (await tester.runAsync(Harness.create))!;
  await tester.runAsync(() async {
    await h.services.repo.create(const ScriptDraft(work: '햄릿', body: '그분이 미치셨다니'));
    await h.services.repo.create(const ScriptDraft(work: '갈매기', body: '나는 갈매기'));
  });
  return h;
}

void main() {
  testWidgets('펼친 폴드에서는 대본을 누르면 목록 옆 칸에 열리고, 탭은 아래에 그대로 둔다', (tester) async {
    setWindow(tester, unfoldedFold);
    final h = await harnessWithScripts(tester);
    await tester.pumpWidget(h.wrap(const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text(nothingOpen), findsOneWidget);

    await tester.tap(find.text('햄릿'));
    await tester.pumpAndSettle();
    expect(bodyText('그분이 미치셨다니'), findsOneWidget);
    expect(find.text('갈매기'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('갈매기'));
    await tester.pumpAndSettle();
    expect(bodyText('나는 갈매기'), findsOneWidget);
    expect(bodyText('그분이 미치셨다니'), findsNothing);
    await tester.runAsync(h.db.close);
  });

  testWidgets('아이패드 가로 화면에서는 탭을 왼쪽 레일로 오간다', (tester) async {
    setWindow(tester, iPadLandscape);
    final h = await harnessWithScripts(tester);
    await tester.pumpWidget(h.wrap(const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(railDestination('모음'));
    await tester.pumpAndSettle();
    expect(find.text('새 모음'), findsOneWidget);
    expect(find.text('햄릿'), findsNothing);

    await tester.tap(railDestination('대본'));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('폴드를 접으면 보던 대본을 한 화면으로 이어 보고, 다시 펼치면 목록 옆 칸으로 돌아온다', (tester) async {
    setWindow(tester, unfoldedFold);
    final h = await harnessWithScripts(tester);
    await tester.pumpWidget(h.wrap(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('햄릿'));
    await tester.pumpAndSettle();

    setWindow(tester, phone);
    await tester.pumpAndSettle();
    expect(bodyText('그분이 미치셨다니'), findsOneWidget);
    expect(find.text('갈매기'), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    setWindow(tester, unfoldedFold);
    await tester.pumpAndSettle();
    expect(bodyText('그분이 미치셨다니'), findsOneWidget);
    expect(find.text('갈매기'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    // 접은 채로 대본을 닫으면 다시 펼쳐도 옆 칸은 비어 있다
    setWindow(tester, phone);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('갈매기'), findsOneWidget);
    setWindow(tester, unfoldedFold);
    await tester.pumpAndSettle();
    expect(find.text(nothingOpen), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('목록 옆 칸에서 대본을 지우면 옆 칸이 비고 목록에서도 빠진다', (tester) async {
    setWindow(tester, iPadPortrait);
    final h = await harnessWithScripts(tester);
    await tester.pumpWidget(h.wrap(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('햄릿'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pump();
    await settleIo(tester);
    await tester.pumpAndSettle();

    expect(find.text(nothingOpen), findsOneWidget);
    expect(find.text('햄릿'), findsNothing);
    expect(find.text('갈매기'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('아이패드를 돌려 레일이 생기거나 없어져도 검색어와 열어 둔 대본이 그대로다', (tester) async {
    setWindow(tester, iPadPortrait);
    final h = await harnessWithScripts(tester);
    await tester.pumpWidget(h.wrap(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), '미치');
    await tester.pumpAndSettle();
    await tester.tap(find.text('햄릿'));
    await tester.pumpAndSettle();

    void expectKept() {
      expect(find.text('미치'), findsOneWidget);
      expect(find.text('갈매기'), findsNothing);
      expect(bodyText('그분이 미치셨다니'), findsOneWidget);
    }

    setWindow(tester, iPadLandscape);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expectKept();

    setWindow(tester, iPadPortrait);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expectKept();
    await tester.runAsync(h.db.close);
  });

  testWidgets('모음 안 대본도 넓은 창에서는 목록 옆 칸에 열고, 옆 칸에는 뒤로 가기 버튼을 따로 두지 않는다', (tester) async {
    setWindow(tester, iPadLandscape);
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      final audition = await h.services.repo.createCollection('1차 오디션');
      await h.services.repo.create(ScriptDraft(work: '햄릿', body: '그분이 미치셨다니', collectionIds: [audition]));
    });
    await tester.pumpWidget(h.wrap(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(railDestination('모음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1차 오디션'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('햄릿'));
    await tester.pumpAndSettle();

    expect(bodyText('그분이 미치셨다니'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('모음 그리드는 넓은 창에서 한 줄에 더 많이 놓는다', (tester) async {
    setWindow(tester, phone);
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const CollectionsScreen()));
    await tester.pumpAndSettle();
    double rowOf(String name) => tester.getTopLeft(find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first).dy;
    expect(rowOf('즐겨찾기'), rowOf('전체'));
    expect(rowOf('새 모음'), greaterThan(rowOf('전체')));

    setWindow(tester, unfoldedFold);
    await tester.pumpAndSettle();
    expect(rowOf('새 모음'), rowOf('전체'));
    await tester.runAsync(h.db.close);
  });

  testWidgets('넓은 화면에서도 대본 본문과 편집 칸은 읽기 좋은 폭으로 가운데에 둔다', (tester) async {
    setWindow(tester, iPadLandscape);
    final h = (await tester.runAsync(Harness.create))!;
    final id = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(work: '햄릿', body: '그분이 미치셨다니'))))!;
    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: id)));
    await tester.pumpAndSettle();
    expect(tester.getSize(bodyText('그분이 미치셨다니')).width, lessThanOrEqualTo(readableWidth));
    expect(tester.getCenter(bodyText('그분이 미치셨다니')).dx, closeTo(iPadLandscape.width / 2, 1));

    await tester.tap(find.byTooltip('편집'));
    await tester.pumpAndSettle();
    final work = find.widgetWithText(TextFormField, '작품명');
    expect(tester.getSize(work).width, lessThanOrEqualTo(readableWidth));
    expect(tester.getCenter(work).dx, closeTo(iPadLandscape.width / 2, 1));
    await tester.runAsync(h.db.close);
  });
}
