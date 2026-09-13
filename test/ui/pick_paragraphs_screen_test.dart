import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ocr/assemble_text.dart';
import 'package:monologue/ui/capture/pick_paragraphs_screen.dart';

const _instagram = [
  Paragraph(photoNumber: 1, text: 'kim actor 팔로우', isChrome: true),
  Paragraph(photoNumber: 1, text: '나는 늘 괜찮다고 말했어. 아침에 눈을 뜰 때도,'),
  Paragraph(photoNumber: 1, text: '괜찮다는 말은 참 편리하더라.'),
  Paragraph(photoNumber: 1, text: '좋아요 1,242개', isChrome: true),
  Paragraph(photoNumber: 1, text: '#독백 #연기', isChrome: true),
];

/// 화면을 띄우고, 닫힐 때 돌려준 문단을 담을 상자를 함께 준다.
Future<List<Paragraph>?> Function() await_ = () async => null;

class _Host extends StatelessWidget {
  const _Host({required this.paragraphs, required this.onResult});

  final List<Paragraph> paragraphs;
  final ValueChanged<List<Paragraph>?> onResult;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  onResult(await Navigator.of(context).push<List<Paragraph>>(
                    MaterialPageRoute(builder: (_) => PickParagraphsScreen(paragraphs: paragraphs)),
                  ));
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
}

/// 화면을 열고, 결과를 받을 상자를 돌려준다.
Future<List<List<Paragraph>?>> openPicker(WidgetTester tester, List<Paragraph> paragraphs) async {
  final box = <List<Paragraph>?>[];
  await tester.pumpWidget(_Host(paragraphs: paragraphs, onResult: box.add));
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return box;
}

Future<void> tapContinue(WidgetTester tester) async {
  await tester.tap(find.textContaining('로 계속'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('본문은 켜지고 앱 화면 글자는 꺼진 채로 시작한다', (tester) async {
    final box = await openPicker(tester, _instagram);
    expect(find.textContaining('5개 중 2개'), findsOneWidget);

    await tapContinue(tester);
    expect(box.single?.map((p) => p.text).toList(), [
      '나는 늘 괜찮다고 말했어. 아침에 눈을 뜰 때도,',
      '괜찮다는 말은 참 편리하더라.',
    ]);
  });

  testWidgets('문단을 탭하면 선택이 바뀐다', (tester) async {
    final box = await openPicker(tester, _instagram);
    await tester.tap(find.text('#독백 #연기'));
    await tester.tap(find.text('나는 늘 괜찮다고 말했어. 아침에 눈을 뜰 때도,'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5개 중 2개'), findsOneWidget);

    await tapContinue(tester);
    expect(box.single?.map((p) => p.text).toList(), ['괜찮다는 말은 참 편리하더라.', '#독백 #연기']);
  });

  testWidgets('확신도가 낮은 문단에는 확인 필요 표시가 붙는다', (tester) async {
    await openPicker(tester, const [
      Paragraph(photoNumber: 1, text: '인쇄된 대사', confidence: 0.94),
      Paragraph(photoNumber: 1, text: '손으로 쓴 메모', confidence: 0.3),
    ]);
    expect(find.text('확인 필요'), findsOneWidget);
  });

  testWidgets('사진이 여러 장이면 몇 번째 사진인지 보여준다', (tester) async {
    await openPicker(tester, const [
      Paragraph(photoNumber: 1, text: '첫 장 본문'),
      Paragraph(photoNumber: 2, text: '둘째 장 본문'),
    ]);
    expect(find.text('1번째 사진'), findsOneWidget);
    expect(find.text('2번째 사진'), findsOneWidget);
  });

  testWidgets('사진이 한 장이면 사진 번호를 보여주지 않는다', (tester) async {
    await openPicker(tester, const [
      Paragraph(photoNumber: 1, text: '본문 하나'),
      Paragraph(photoNumber: 1, text: '본문 둘'),
    ]);
    expect(find.textContaining('번째 사진'), findsNothing);
  });

  testWidgets('모두 끄면 계속 버튼을 누를 수 없다', (tester) async {
    await openPicker(tester, const [Paragraph(photoNumber: 1, text: '본문 하나')]);
    await tester.tap(find.text('본문 하나'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });
}
