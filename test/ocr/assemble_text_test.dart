import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ocr/assemble_text.dart';

OcrBlock b(double top, List<String> lines, {double left = 0}) => OcrBlock(top: top, left: left, lines: lines);

void main() {
  group('joinLines', () {
    test('블록 안의 줄은 사진의 줄바꿈 그대로 잇는다', () {
      expect(joinLines(['나는 늘 괜찮다고', '말했어.']), '나는 늘 괜찮다고\n말했어.');
    });
    test('줄 안의 연속 공백을 정리하고 빈 줄은 건너뛴다', () {
      expect(joinLines(['  괜찮지   않아 ', '', ' 하나도 ']), '괜찮지 않아\n하나도');
    });
  });

  group('assembleText', () {
    test('블록을 위에서 아래로 정렬하고 빈 줄로 나눈다', () {
      final page = [b(200, ['둘째 문단']), b(10, ['첫 문단'])];
      expect(assembleText([page]), '첫 문단\n\n둘째 문단');
    });
    test('같은 높이면 왼쪽 블록이 먼저', () {
      final page = [b(10, ['오른쪽'], left: 300), b(10, ['왼쪽'], left: 5)];
      expect(assembleText([page]), '왼쪽\n\n오른쪽');
    });
    test('이미지 사이는 빈 줄 하나로 잇는다', () {
      expect(assembleText([[b(0, ['첫 장'])], [b(0, ['둘째 장'])]]), '첫 장\n\n둘째 장');
    });
    test('글자가 없는 블록과 이미지는 건너뛴다', () {
      expect(assembleText([[b(0, ['  '])], [], [b(0, ['본문'])]]), '본문');
    });
  });
}
