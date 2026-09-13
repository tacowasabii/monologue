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

  testWidgets('즐겨찾기 토글과 필터 시트로 목록을 거른다', (tester) async {
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

    await tester.tap(find.byTooltip('즐겨찾기만 보기'));
    await tester.pumpAndSettle();
    expect(find.text('갈매기'), findsOneWidget);
    expect(find.text('햄릿'), findsNothing);

    await tester.tap(find.byTooltip('즐겨찾기 필터 해제'));
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
