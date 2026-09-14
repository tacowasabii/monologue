import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_filter.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/common/pill_chip.dart';
import 'package:monologue/ui/edit/script_edit_screen.dart';

import 'test_harness.dart';

Future<String> makePhoto() async {
  final dir = await Directory.systemTemp.createTemp('monologue_photo');
  final f = File('${dir.path}/shot.png');
  await f.writeAsBytes([1, 2, 3]);
  return f.path;
}

/// 사진 복사는 실제 파일 입출력이라, 가짜 시간 대신 실제로 기다렸다가 화면을 갱신한다.
Future<void> tapSaveAndWait(WidgetTester tester) async {
  await tester.tap(find.text('저장'));
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

void main() {
  testWidgets('본문이 비면 저장하지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('본문을 입력해 주세요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('기본 정보는 작품명·메모이고 제목·인물 칸은 없다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen()));
    await tester.pumpAndSettle();
    expect(find.text('제목'), findsNothing);
    expect(find.text('인물'), findsNothing);
    for (final label in ['작품명', '메모']) {
      expect(find.widgetWithText(TextFormField, label), findsOneWidget, reason: label);
    }
    await tester.runAsync(h.db.close);
  });

  testWidgets('메모를 적어 저장하면 대본과 함께 저장된다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '괜찮다는 말은\n참 편리하더라')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '메모'), '2차 오디션 지정 대사');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final list = await tester.runAsync(() => h.services.repo.watchScripts(const ScriptFilter()).first);
    expect(list!.single.script.memo, '2차 오디션 지정 대사');
    await tester.runAsync(h.db.close);
  });

  testWidgets('즐겨찾기 스위치는 없고, 고른 모음과 함께 저장한다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final repo = h.services.repo;
    await tester.runAsync(() async {
      await repo.createCollection('1차 오디션');
      await repo.createCollection('입시');
    });
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '본문')));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNothing);

    await tester.ensureVisible(find.text('입시'));
    await tester.tap(find.text('입시'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final ids = await tester.runAsync(() async {
      final list = await repo.watchScripts(const ScriptFilter()).first;
      final detail = await repo.watchScript(list.single.script.id).first;
      return (detail!.collectionIds, (await repo.findCollection('입시'))!.id);
    });
    expect(ids!.$1, [ids.$2]);
    await tester.runAsync(h.db.close);
  });

  testWidgets('모음 안에서 추가하면 그 모음이 미리 선택돼 있다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final audition = (await tester.runAsync(() => h.services.repo.createCollection('1차 오디션')))!;
    await tester.pumpWidget(h.wrap(ScriptEditScreen(initialBody: '본문', initialCollectionIds: [audition])));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1차 오디션'));
    expect(tester.widget<PillChip>(find.widgetWithText(PillChip, '1차 오디션')).selected, isTrue);
    await tester.runAsync(h.db.close);
  });

  testWidgets('이미 만든 태그가 입력하지 않아도 보이고, 누르면 붙는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: 'x', tags: ['코미디', '슬픔'])));
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '본문')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('만든 태그'));
    expect(find.widgetWithText(ActionChip, '#코미디'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, '#코미디'));
    await tester.pumpAndSettle();
    // 붙인 태그는 위쪽 칩으로 올라가고 만든 태그 목록에서는 빠진다
    expect(find.widgetWithText(InputChip, '#코미디'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '#코미디'), findsNothing);
    expect(find.widgetWithText(ActionChip, '#슬픔'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('사진으로 만든 대본을 처음 저장하면 사진 보관 안내를 보여 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final photo = (await tester.runAsync(makePhoto))!;
    await tester.pumpWidget(h.wrap(ScriptEditScreen(initialBody: '본문', newImagePaths: [photo])));
    await tester.pumpAndSettle();

    await tapSaveAndWait(tester);
    expect(find.text('사진도 함께 보관했어요'), findsOneWidget);
    expect(find.textContaining(keepWords('설정 → 사용 방법')), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('사진도 함께 보관했어요'), findsNothing);
    await tester.runAsync(h.db.close);
  });

  testWidgets('사진 보관 안내를 이미 봤으면 다시 보여 주지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final photo = (await tester.runAsync(makePhoto))!;
    await tester.runAsync(h.services.tips.takePhotoKept);
    await tester.pumpWidget(h.wrap(ScriptEditScreen(initialBody: '본문', newImagePaths: [photo])));
    await tester.pumpAndSettle();

    await tapSaveAndWait(tester);
    // 저장은 끝났는데 안내는 뜨지 않아야 한다
    final list = await tester.runAsync(() => h.services.repo.watchScripts(const ScriptFilter()).first);
    expect(list!.single.script.body, '본문');
    expect(find.text('사진도 함께 보관했어요'), findsNothing);
    await tester.runAsync(h.db.close);
  });

  testWidgets('사진 없이 저장하면 사진 보관 안내를 보여 주지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '본문')));
    await tester.pumpAndSettle();
    await tapSaveAndWait(tester);
    expect(find.text('사진도 함께 보관했어요'), findsNothing);
    await tester.runAsync(h.db.close);
  });

  testWidgets('인물 대사가 두 줄 이상인 새 대본은 대화 형식으로 시작해 저장된다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '민수: 왜 그랬어?\n지영: 몰라.')));
    await tester.pumpAndSettle();
    expect(tester.widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>)).selected, {true});
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final list = await tester.runAsync(() => h.services.repo.watchScripts(const ScriptFilter()).first);
    expect(list!.single.script.dialogue, isTrue);
    await tester.runAsync(h.db.close);
  });
}
