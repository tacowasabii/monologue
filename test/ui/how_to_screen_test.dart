import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/settings/how_to_screen.dart';

void main() {
  Future<void> nextPage(WidgetTester tester) async {
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
  }

  test('사용 방법이 한 번 보고 지나치기 쉬운 기능을 모두 다룬다', () {
    expect(howToSlides.map((s) => s.title), [
      '사진으로 대본 만들기',
      '넣을 문단 고르기',
      '원본 사진 보관',
      '모음으로 정리하기',
      '대화 대본과 내 역할',
      '연기 노트와 몰입 읽기',
      '연습 기록 남기기',
      '링크로 대본 보내기',
      '기기를 바꿀 때는 백업',
    ]);
    // 사진첩을 비워도 된다는 핵심 내용이 들어 있어야 한다
    expect(howToSlides.expand((s) => s.points).where((p) => p.contains('사진첩에서 캡처를 지워도')), hasLength(1));
  });

  testWidgets('설정에서 연 사용 방법은 한 장씩 넘기고, 이전으로 돌아가고, 완료로 닫는다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HowToScreen())),
          child: const Text('열기'),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('사용 방법'), findsOneWidget);
    expect(find.text('건너뛰기'), findsNothing);
    expect(find.text('이전'), findsNothing);

    for (final (i, slide) in howToSlides.indexed) {
      expect(find.text(keepWords(slide.title)), findsOneWidget, reason: slide.title);
      for (final point in slide.points) {
        expect(find.text(keepWords(point)), findsOneWidget, reason: point);
      }
      if (i < howToSlides.length - 1) await nextPage(tester);
    }
    expect(find.text('다음'), findsNothing);

    await tester.tap(find.text('이전'));
    await tester.pumpAndSettle();
    expect(find.text(keepWords(howToSlides[howToSlides.length - 2].title)), findsOneWidget);

    await nextPage(tester);
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();
    expect(find.byType(HowToScreen), findsNothing);
    expect(find.text('열기'), findsOneWidget);
  });

  testWidgets('옆으로 밀어서도 넘길 수 있다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HowToScreen()));
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(keepWords(howToSlides[1].title)), findsOneWidget);
    expect(find.text('이전'), findsOneWidget);
  });

  testWidgets('처음 켰을 때는 건너뛰기와 마지막 장의 시작하기로 끝낸다', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(home: HowToScreen(firstRun: true, onDone: () => done++)));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    expect(done, 1);

    for (var i = 0; i < howToSlides.length - 1; i++) {
      await nextPage(tester);
    }
    expect(find.text('건너뛰기'), findsNothing);
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    expect(done, 2);
  });

  testWidgets('처음 켰을 때 뒤로 가기는 앞 장으로 돌아간다', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HowToScreen(firstRun: true, onDone: () {})));
    await nextPage(tester);
    await nextPage(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(keepWords(howToSlides[1].title)), findsOneWidget);
  });

  testWidgets('작은 폰, 가로로 눕힌 폰, 태블릿에서 큰 글자로 봐도 넘치지 않는다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(320, 568), Size(780, 360), Size(1024, 1366)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(key: ValueKey(size), home: HowToScreen(firstRun: true, onDone: () {})));
      await tester.pumpAndSettle();
      for (var i = 0; i < howToSlides.length - 1; i++) {
        await nextPage(tester);
      }
      expect(find.text('시작하기'), findsOneWidget, reason: '$size');
    }
  });
}
