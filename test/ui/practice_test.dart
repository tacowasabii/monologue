import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/practice/practice_section.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

/// 파일 복사·삭제 같은 실제 입출력이 끝나도록 실제 시간으로 기다렸다가 화면을 갱신한다.
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

/// 대본 화면을 열고 연습 기록 구역까지 내린다.
Future<void> openScript(WidgetTester tester, Harness h, int id) async {
  await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: id)));
  await tester.pumpAndSettle();
  // 본문(SelectableText)에도 스크롤 영역이 있어서 바깥 목록을 직접 가리킨다
  await tester.scrollUntilVisible(find.text('추가'), 200, scrollable: find.byType(Scrollable).first);
}

Future<void> chooseAdd(WidgetTester tester, String label) async {
  await tester.tap(find.text('추가'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
}

void main() {
  test('takeTitle은 9월 13일 오후 9:30처럼 쓴다', () {
    expect(takeTitle(DateTime(2026, 9, 13, 21, 30)), '9월 13일 오후 9:30');
    expect(takeTitle(DateTime(2026, 9, 13, 0, 5)), '9월 13일 오전 12:05');
    expect(takeTitle(DateTime(2026, 9, 13, 12, 0)), '9월 13일 오후 12:00');
  });

  testWidgets('대본 화면 아래에 연습 기록이 최근 순으로 보이고, 길게 눌러 지울 수 있다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final repo = h.services.repo;
    final media = h.services.media;
    final id = (await tester.runAsync(() async {
      final id = await repo.create(const ScriptDraft(work: '햄릿', body: '그분이 미치셨다니'));
      for (final (kind, minute, ext) in [(MediaKind.audio, 30, '.m4a'), (MediaKind.video, 45, '.mp4')]) {
        final name = media.newFileName(ext);
        await File(media.pathOf(name)).writeAsBytes([1, 2, 3]);
        await repo.addMedia(
          id,
          kind: kind,
          storedFileName: name,
          duration: const Duration(seconds: 65),
          createdAt: DateTime(2026, 9, 13, 21, minute),
        );
      }
      return id;
    }))!;
    await openScript(tester, h, id);

    final titles = [for (final t in tester.widgetList<ListTile>(find.byType(ListTile))) (t.title! as Text).data];
    expect(titles, ['9월 13일 오후 9:45', '9월 13일 오후 9:30']);
    expect(find.text('영상 · 1:05'), findsOneWidget);
    expect(find.text('음성 · 1:05'), findsOneWidget);

    await tester.longPress(find.text('9월 13일 오후 9:45'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('지우기'));
    await tester.pump();
    await settleIo(tester);
    expect(find.text('9월 13일 오후 9:45'), findsNothing);
    expect(await tester.runAsync(() => repo.watchMedia(id).first), hasLength(1));
    await tester.runAsync(h.db.close);
  });

  testWidgets('녹음하기: 대본을 보면서 녹음하고, 멈추면 기록이 생긴다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final id = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: '나는 늘 괜찮다고 말했어.'))))!;
    // 녹음 파일에서 읽은 실제 길이
    h.picker.audioLength = const Duration(milliseconds: 4038);
    await openScript(tester, h, id);

    await chooseAdd(tester, '녹음하기');
    await tester.pumpAndSettle();
    expect(find.text('녹음'), findsOneWidget); // 녹음 화면 제목
    expect(find.text(keepWords('나는 늘 괜찮다고 말했어.')), findsOneWidget);

    await tester.tap(find.text('녹음 시작'));
    await settleIo(tester);
    expect(find.text('멈추고 저장'), findsOneWidget);
    expect(h.recorder.startedPath, isNotNull);

    await tester.tap(find.text('멈추고 저장'));
    await tester.pump();
    await settleIo(tester);
    await tester.pumpAndSettle();

    final takes = (await tester.runAsync(() => h.services.repo.watchMedia(id).first))!;
    expect(takes.single.kind, MediaKind.audio);
    // 화면 타이머가 아니라 파일에서 읽은 길이로 남긴다
    expect(takes.single.durationMs, 4038);
    expect(File(h.services.media.pathOf(takes.single.fileName)).existsSync(), isTrue);
    expect(find.text('연습 기록'), findsOneWidget); // 대본 화면으로 돌아왔다
    await tester.runAsync(h.db.close);
  });

  testWidgets('녹음 중에 나가려고 하면 버릴지 묻고, 버리면 기록도 파일도 남지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final id = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: '본문'))))!;
    await openScript(tester, h, id);
    await chooseAdd(tester, '녹음하기');
    await tester.pumpAndSettle();
    await tester.tap(find.text('녹음 시작'));
    await settleIo(tester);
    final path = h.recorder.startedPath!;

    // pageBack()은 영어 툴팁('Back')으로 버튼을 찾아서 한국어 화면에서는 쓸 수 없다
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('녹음을 버릴까요?'), findsOneWidget);

    await tester.tap(find.text('버리기'));
    await tester.pump();
    await settleIo(tester);
    await tester.pumpAndSettle();

    expect(await tester.runAsync(() => h.services.repo.watchMedia(id).first), isEmpty);
    expect(File(path).existsSync(), isFalse);
    expect(find.text('연습 기록'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('마이크 권한이 없으면 안내하고 녹음을 시작하지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final id = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: '본문'))))!;
    h.recorder.permission = false;
    await openScript(tester, h, id);
    await chooseAdd(tester, '녹음하기');
    await tester.pumpAndSettle();

    await tester.tap(find.text('녹음 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('마이크 권한이 필요해요. 설정 앱에서 허용해 주세요.'), findsOneWidget);
    expect(find.text('녹음 시작'), findsOneWidget);
    expect(h.recorder.startedPath, isNull);
    await tester.runAsync(h.db.close);
  });

  testWidgets('파일 올리기: 사진첩과 파일 중에 고르고, 취소하면 아무것도 남지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final repo = h.services.repo;
    final id = (await tester.runAsync(() => repo.create(const ScriptDraft(body: '본문'))))!;
    final (voice, video) = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('monologue_pick');
      final voice = File('${dir.path}/voice.m4a')..writeAsBytesSync([5, 5]);
      final video = File('${dir.path}/take.mp4')..writeAsBytesSync([7, 7, 7]);
      return (voice.path, video.path);
    }))!;
    await openScript(tester, h, id);

    Future<void> importFrom(String source) async {
      await chooseAdd(tester, '파일 올리기');
      await tester.pumpAndSettle();
      await tester.tap(find.text(source));
      await tester.pump();
      await settleIo(tester);
    }

    // 고르다가 취소
    h.picker.next = null;
    await importFrom('파일');
    expect(await tester.runAsync(() => repo.watchMedia(id).first), isEmpty);

    // 파일 앱의 음성 파일, 사진첩의 영상
    h.picker.next = (path: voice, kind: MediaKind.audio, duration: const Duration(seconds: 42));
    await importFrom('파일');
    h.picker.next = (path: video, kind: MediaKind.video, duration: const Duration(seconds: 90));
    await importFrom('사진첩');

    expect(h.picker.calls, ['files', 'files', 'gallery']);
    final takes = (await tester.runAsync(() => repo.watchMedia(id).first))!;
    expect({for (final t in takes) t.kind: t.durationMs}, {MediaKind.audio: 42000, MediaKind.video: 90000});
    final videoTake = takes.firstWhere((t) => t.kind == MediaKind.video);
    expect(File(h.services.media.pathOf(videoTake.fileName)).readAsBytesSync(), [7, 7, 7]);
    expect(find.text('음성 · 0:42'), findsOneWidget);
    expect(find.text('영상 · 1:30'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
