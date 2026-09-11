import 'package:flutter_test/flutter_test.dart';
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

  test('입력 순서와 상관없이 위→아래, 같은 줄은 왼→오', () {
    final blocks = groupLines([l('87%', 10, left: 300), l('본문', 200), l('9:41', 10, left: 5)]);
    expect(blocks.map((b) => b.lines), [
      ['9:41', '87%'],
      ['본문'],
    ]);
    expect(blocks.first.top, 10);
  });

  test('top이 줄 높이 절반 이내로 다르면 같은 줄로 보고 왼→오 순서', () {
    // 인물명과 대사가 따로 인식되면 글꼴 차이로 top이 조금 어긋난다
    final blocks = groupLines([l('사느냐 죽느냐', 98, left: 120), l('햄릿:', 103, left: 10), l('그것이 문제로다', 130, left: 10)]);
    expect(blocks.map((b) => b.lines), [
      ['햄릿:', '사느냐 죽느냐', '그것이 문제로다'],
    ]);
    expect(joinLines(blocks.single.lines), '햄릿: 사느냐 죽느냐 그것이 문제로다');
  });

  test('빈 줄과 빈 입력은 무시한다', () {
    expect(groupLines([]), isEmpty);
    expect(groupLines([l('   ', 10)]), isEmpty);
  });

  test('groupLines 결과를 assembleText에 넣으면 문단이 빈 줄로 나뉜다', () {
    final page = groupLines([l('괜찮다는 말은', 100), l('참 편리하더라.', 130), l('그런데 오늘은', 200)]);
    expect(assembleText([page]), '괜찮다는 말은 참 편리하더라.\n\n그런데 오늘은');
  });
}
