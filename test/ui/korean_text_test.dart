import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ui/common/korean_text.dart';

const wj = '\u2060';

void main() {
  test('단어 안의 글자 사이에만 줄바꿈 금지 문자를 넣는다', () {
    expect(keepWords('뜰 때도, 버스'), '뜰 때$wj도$wj, 버$wj스');
    expect(keepWords('가\n나다'), '가\n나$wj다');
  });

  test('이모지처럼 여러 코드로 된 글자는 가르지 않는다', () {
    expect(keepWords('👍🏽'), '👍🏽');
    expect(keepWords('좋아👍🏽'), '좋$wj아$wj👍🏽');
  });

  test('withoutWordJoiners는 원래 글로 되돌린다', () {
    const text = '나는 늘 괜찮다고 말했어.\n아침에 👍🏽 눈을 뜰 때도,';
    expect(withoutWordJoiners(keepWords(text)), text);
  });
}
