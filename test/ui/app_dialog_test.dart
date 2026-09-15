import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/design/design.dart';
import 'package:monologue/ui/theme.dart';

void main() {
  Future<List<bool>> pumpOpener(WidgetTester tester, {bool destructive = false}) async {
    final results = <bool>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await showConfirmDialog(
            context,
            title: '대본을 삭제할까요?',
            message: '원본 사진과 연습 기록도 함께 지워져요.',
            confirmLabel: '삭제',
            destructive: destructive,
          )),
          child: const Text('열기'),
        ),
      ),
    ));
    return results;
  }

  testWidgets('확인 창은 제목·설명과 넓은 두 버튼을 보여 주고, 누른 버튼이나 창 밖에 따라 결과를 돌려준다', (tester) async {
    final results = await pumpOpener(tester);

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('대본을 삭제할까요?'), findsOneWidget);
    expect(find.text(keepWords('원본 사진과 연습 기록도 함께 지워져요.')), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '취소'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '삭제'), findsOneWidget);
    // 두 버튼이 창 너비를 나눠 가진다
    expect(tester.getSize(find.byType(OutlinedButton)).width, tester.getSize(find.byType(FilledButton)).width);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // 창 밖
    await tester.pumpAndSettle();

    expect(results, [false, true, false]);
  });

  testWidgets('되돌릴 수 없는 동작이면 확인 버튼을 경고색으로 채운다', (tester) async {
    await pumpOpener(tester, destructive: true);
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final context = tester.element(find.byType(FilledButton));
    expect(button.style?.backgroundColor?.resolve({}), Theme.of(context).colorScheme.error);
  });

  Future<void> pumpDialog(WidgetTester tester, AppDialog dialog) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(context: context, builder: (_) => dialog),
          child: const Text('열기'),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('버튼이 셋이면 위에서부터 같은 폭으로 쌓고, 가장 약한 버튼은 글자만 둔다', (tester) async {
    await pumpDialog(
      tester,
      AppDialog(
        title: '노트도 함께 보낼까요?',
        actions: [
          AppAction('함께 보내기', onPressed: () {}),
          AppAction('노트 빼고 보내기', kind: AppActionKind.secondary, onPressed: () {}),
          AppAction('취소', kind: AppActionKind.quiet, onPressed: () {}),
        ],
      ),
    );
    final primary = find.widgetWithText(FilledButton, '함께 보내기');
    final secondary = find.widgetWithText(OutlinedButton, '노트 빼고 보내기');
    final quiet = find.widgetWithText(TextButton, '취소');
    expect(tester.getTopLeft(primary).dy, lessThan(tester.getTopLeft(secondary).dy));
    expect(tester.getTopLeft(secondary).dy, lessThan(tester.getTopLeft(quiet).dy));
    expect(tester.getSize(primary).width, tester.getSize(secondary).width);
    expect(tester.getSize(secondary).width, tester.getSize(quiet).width);
  });

  testWidgets('확인할 수 없는 동안에는 권하는 버튼을 누를 수 없다', (tester) async {
    await pumpDialog(
      tester,
      const AppDialog(
        title: '새 모음',
        content: TextField(),
        actions: [AppAction('만들기', onPressed: null)],
      ),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '만들기')).onPressed, isNull);
  });
}
