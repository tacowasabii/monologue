import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/dialogue.dart';
import 'package:monologue/ocr/assemble_text.dart';

OcrLine l(String text, double top, {double left = 0, double height = 20}) =>
    OcrLine(text: text, top: top, left: left, height: height);

void main() {
  test('줄 간격이 좁으면 한 문단으로 묶는다', () {
    final blocks = groupLines([l('나는 늘 괜찮다고', 100), l('말했어.', 130)]);
    expect(blocks.map((b) => b.lines), [
      ['나는 늘 괜찮다고', '말했어.'],
    ]);
  });

  test('줄 높이보다 큰 간격이 있으면 새 문단', () {
    final blocks = groupLines([l('첫 문단', 100), l('이어짐', 130), l('둘째 문단', 190)]);
    expect(blocks.map((b) => b.lines), [
      ['첫 문단', '이어짐'],
      ['둘째 문단'],
    ]);
  });

  test('입력 순서와 상관없이 위→아래, 같은 행의 조각은 왼→오로 이어 한 줄', () {
    // 상태바처럼 보이는 글자는 쓰지 않는다(맨 윗줄이면 상태바 규칙으로 빠진다)
    final blocks = groupLines([l('대사', 10, left: 300), l('본문', 200), l('햄릿', 10, left: 5)]);
    expect(blocks.map((b) => b.lines), [
      ['햄릿 대사'],
      ['본문'],
    ]);
    expect(blocks.first.top, 10);
  });

  test('top이 줄 높이 절반 이내로 다르면 같은 행으로 보고 왼→오로 이어 한 줄', () {
    // 인물명과 대사가 따로 인식되면 글꼴 차이로 top이 조금 어긋난다
    final blocks = groupLines([l('사느냐 죽느냐', 98, left: 120), l('햄릿:', 103, left: 10), l('그것이 문제로다', 130, left: 10)]);
    expect(blocks.map((b) => b.lines), [
      ['햄릿: 사느냐 죽느냐', '그것이 문제로다'],
    ]);
    expect(joinLines(blocks.single.lines), '햄릿: 사느냐 죽느냐\n그것이 문제로다');
  });

  test('한 줄에 한 문장씩 끊어 쓴 대본은 줄 간격이 좁아도 줄바꿈이 남는다', () {
    final page = groupLines([
      l('아이, 참... 아이, 평상시에 좀 잘해, 평상시에', 100),
      l('뭘, 뭐 이제 와서 좋은 아빠인 척하고 있어', 125),
      l('아니다, 쩝. 이 정도면 좋은 아빠지, 뭐', 150),
    ]);
    expect(
      assembleText([page]),
      '아이, 참... 아이, 평상시에 좀 잘해, 평상시에\n뭘, 뭐 이제 와서 좋은 아빠인 척하고 있어\n아니다, 쩝. 이 정도면 좋은 아빠지, 뭐',
    );
  });

  test('줄 간격이 좁은 대화 캡처도 줄마다 인물 대사로 나뉜다', () {
    final text = assembleText([
      groupLines([l('민수: 왜 연락 안 했어?', 100), l('지영: 바빴어.', 125), l('민수: 거짓말하지 마.', 150)]),
    ]);
    expect(looksLikeDialogue(text), isTrue);
    expect(speakersOf(parseDialogue(text)), ['민수', '지영']);
    expect(parseDialogue(text).where((d) => d.speaker != null), hasLength(3));
  });

  group('캡처 상태바', () {
    test('맨 윗줄이 시각·통신·배터리 표시뿐이면 버린다', () {
      final blocks = groupLines([
        l('9:41', 10, left: 5),
        l('5G 87%', 11, left: 300),
        l('괜찮다는 말', 100),
        l('나는 늘 괜찮다고', 160),
      ]);
      expect(blocks.expand((b) => b.lines), ['괜찮다는 말', '나는 늘 괜찮다고']);
    });

    test('통신사·LTE·와이파이 표기도 상태바로 본다', () {
      final blocks = groupLines([l('SKT LTE', 10, left: 5), l('오후 2:03', 10, left: 150), l('97 %', 10, left: 300), l('본문', 100)]);
      expect(blocks.expand((b) => b.lines), ['본문']);
    });

    test('상태바처럼 보여도 맨 윗줄이 아니면 남긴다', () {
      final blocks = groupLines([l('대사 시작', 10), l('10:30', 100)]);
      expect(blocks.expand((b) => b.lines), ['대사 시작', '10:30']);
    });

    test('맨 윗줄에 다른 글자가 섞여 있으면 남긴다', () {
      final blocks = groupLines([l('9:41 독백', 10)]);
      expect(blocks.single.lines, ['9:41 독백']);
    });
  });

  test('빈 줄과 빈 입력은 무시한다', () {
    expect(groupLines([]), isEmpty);
    expect(groupLines([l('   ', 10)]), isEmpty);
  });

  test('groupLines 결과를 assembleText에 넣으면 문단은 빈 줄로, 문단 안의 줄은 줄바꿈으로 나뉜다', () {
    final page = groupLines([l('괜찮다는 말은', 100), l('참 편리하더라.', 130), l('그런데 오늘은', 200)]);
    expect(assembleText([page]), '괜찮다는 말은\n참 편리하더라.\n\n그런데 오늘은');
  });
}
