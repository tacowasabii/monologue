import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/list/script_list_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('대본이 없으면 안내 문구를 보여준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 대본이 없어요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('카드 제목은 작품명(없으면 본문 첫 줄)이고, 그 아래 메모 첫 줄이 붙는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      await h.services.repo.create(
        const ScriptDraft(work: '햄릿', memo: '오필리어 · 1차 오디션\n지정 대사', body: '그분이 미치셨다니'),
      );
      await h.services.repo.create(const ScriptDraft(body: '나는 늘 괜찮다고 말했어.\n아침에 눈을 뜰 때도'));
    });
    await tester.pumpWidget(h.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('햄릿'), findsOneWidget);
    // 같은 작품의 독백이 여러 개여도 구분되도록 메모는 첫 줄만 보여 준다
    expect(find.text('오필리어 · 1차 오디션'), findsOneWidget);
    expect(find.textContaining('지정 대사'), findsNothing);
    expect(find.text(keepWords('그분이 미치셨다니')), findsOneWidget);
    // 첫 줄이 제목 자리로 올라가면 미리보기는 그다음 줄부터 보여 준다
    expect(find.text('나는 늘 괜찮다고 말했어.'), findsOneWidget);
    expect(find.text(keepWords('아침에 눈을 뜰 때도')), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('모음 안에서는 모음 이름이 제목이고, 비어 있으면 넣는 방법을 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final exam = (await tester.runAsync(() async {
      await h.services.repo.createCollection('입시');
      return h.services.repo.findCollection('입시');
    }))!;
    await tester.pumpWidget(h.wrap(ScriptListScreen(collection: exam)));
    await tester.pumpAndSettle();
    expect(find.text('입시'), findsOneWidget);
    expect(find.text('이 모음에 아직 대본이 없어요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('검색어로 목록을 거른다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      await h.services.repo.create(const ScriptDraft(work: '햄릿', body: '사느냐 죽느냐'));
      await h.services.repo.create(const ScriptDraft(work: '갈매기', body: '나는 갈매기', gender: Gender.female));
    });
    await tester.pumpWidget(h.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), '죽느냐');
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsNothing);
    await tester.runAsync(h.db.close);
  });

  /// 기본 테스트 화면(800×600)은 카드 몇 장만 들어가서 실제 폰 크기로 맞춘다.
  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  double top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

  Future<void> tick(WidgetTester tester) => tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));

  testWidgets('즐겨찾기한 대본은 맨 위 즐겨찾기 구역에 모이고, 검색하면 구역 없이 결과만 보인다', (tester) async {
    usePhoneSize(tester);
    final h = (await tester.runAsync(Harness.create))!;
    final repo = h.services.repo;
    await tester.runAsync(() => repo.create(const ScriptDraft(work: '햄릿', body: 'x')));
    await tick(tester);
    await tester.runAsync(() => repo.create(const ScriptDraft(work: '갈매기', body: 'x', favorite: true)));
    await tick(tester);
    await tester.runAsync(() => repo.create(const ScriptDraft(work: '벚꽃 동산', body: 'x')));
    await tester.pumpWidget(h.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('즐겨찾기 1편'), findsOneWidget);
    expect(find.text('대본 2편'), findsOneWidget);
    expect(find.byTooltip('즐겨찾기만 보기'), findsNothing);
    // 즐겨찾기가 맨 위, 그 아래는 최근 수정순
    expect(top(tester, '갈매기'), lessThan(top(tester, '대본 2편')));
    expect(top(tester, '벚꽃 동산'), lessThan(top(tester, '햄릿')));

    final hamletCard = find.ancestor(of: find.text('햄릿'), matching: find.byType(Card));
    await tester.tap(find.descendant(of: hamletCard, matching: find.byTooltip('즐겨찾기')));
    await tester.pumpAndSettle();
    expect(find.text('즐겨찾기 2편'), findsOneWidget);
    expect(find.text('대본 1편'), findsOneWidget);
    expect(top(tester, '햄릿'), lessThan(top(tester, '대본 1편')));

    await tester.enterText(find.byType(SearchBar), '갈매기');
    await tester.pumpAndSettle();
    expect(find.text('찾은 대본 1편'), findsOneWidget);
    expect(find.textContaining('즐겨찾기 '), findsNothing);
    await tester.runAsync(h.db.close);
  });

  testWidgets('정렬 메뉴에서 작품명순을 고르면 목록 순서가 바뀌고, 고른 정렬을 기억한다', (tester) async {
    usePhoneSize(tester);
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() => h.services.repo.create(const ScriptDraft(work: '가', body: 'x')));
    await tick(tester);
    await tester.runAsync(() => h.services.repo.create(const ScriptDraft(work: '나', body: 'x')));
    await tester.pumpWidget(h.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();
    expect(top(tester, '나'), lessThan(top(tester, '가')));

    await tester.tap(find.byTooltip('정렬 · 최근 수정순'));
    await tester.pumpAndSettle();
    // 글자가 아니라 메뉴 항목을 누른다(글자 자리는 눌림 판정에서 빠져 경고가 난다)
    await tester.tap(find.ancestor(of: find.text('작품명순'), matching: find.byWidgetPredicate((w) => w is CheckedPopupMenuItem)));
    await tester.pumpAndSettle();
    expect(top(tester, '가'), lessThan(top(tester, '나')));
    expect(find.byTooltip('정렬 · 작품명순'), findsOneWidget);
    expect(h.services.homeView.sort.label, '작품명순');
    await tester.runAsync(h.db.close);
  });

  testWidgets('모음 안에서는 정렬 버튼 대신 길게 눌러 끌어서 순서를 바꾸고, 바꾼 순서를 저장한다', (tester) async {
    usePhoneSize(tester);
    final h = (await tester.runAsync(Harness.create))!;
    final repo = h.services.repo;
    final audition = (await tester.runAsync(() async {
      final id = await repo.createCollection('1차 오디션');
      for (final work in ['A', 'B', 'C']) {
        await repo.create(ScriptDraft(work: work, body: 'x', collectionIds: [id]));
      }
      return repo.findCollection('1차 오디션');
    }))!;
    await tester.pumpWidget(h.wrap(ScriptListScreen(collection: audition)));
    await tester.pumpAndSettle();
    expect(find.text('대본 3편 · 길게 눌러 끌면 순서를 바꿔요'), findsOneWidget);
    expect(find.byTooltip('정렬 · 최근 수정순'), findsNothing);
    // 새로 넣은 대본이 맨 위
    expect(top(tester, 'C'), lessThan(top(tester, 'B')));
    expect(top(tester, 'B'), lessThan(top(tester, 'A')));

    // 맨 위의 C를 A 아래로 끌어내린다
    final start = tester.getCenter(find.text('C'));
    final target = tester.getBottomLeft(find.ancestor(of: find.text('A'), matching: find.byType(Card))).dy + 40;
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset(start.dx, start.dy + (target - start.dy) * i / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    void expectOrder() {
      expect(top(tester, 'B'), lessThan(top(tester, 'A')));
      expect(top(tester, 'A'), lessThan(top(tester, 'C')));
    }

    expectOrder();
    // 화면을 새로 열어도 저장한 순서 그대로다
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(h.wrap(ScriptListScreen(collection: audition)));
    await tester.pumpAndSettle();
    expectOrder();
    await tester.runAsync(h.db.close);
  });

  testWidgets('필터 시트로 목록을 거른다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      final r = h.services.repo;
      await r.create(const ScriptDraft(
        work: '햄릿',
        body: '사느냐 죽느냐',
        gender: Gender.male,
        ageRange: AgeRange.twenties,
      ));
      await r.create(const ScriptDraft(
        work: '갈매기',
        body: '나는 갈매기',
        gender: Gender.female,
        ageRange: AgeRange.twenties,
        favorite: true,
      ));
      await r.create(const ScriptDraft(
        work: '벚꽃 동산',
        body: '안녕, 나의 동산',
        gender: Gender.female,
        ageRange: AgeRange.fiftiesPlus,
      ));
    });
    await tester.pumpWidget(h.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('필터'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('여'));
    await tester.pumpAndSettle();
    expect(find.text('대본 2편 보기'), findsOneWidget);
    await tester.tap(find.text('50대 이상'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대본 1편 보기'));
    await tester.pumpAndSettle();

    expect(find.text('벚꽃 동산'), findsOneWidget);
    expect(find.text('갈매기'), findsNothing);
    expect(find.text('성별 여'), findsOneWidget);

    await tester.tap(find.text('초기화'));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
