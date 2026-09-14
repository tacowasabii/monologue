import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/dialogue.dart';

void main() {
  test('summarizeDialogue는 나온 차례대로 인물을 모으고 대사·지문 덩어리를 센다', () {
    const body = '(늦은 밤, 편의점 앞)\n\n민수: 왜 연락 안 했어?\n지영: 바빴어.\n그냥... 좀 바빴어.\n민수: 거짓말하지 마.\n(지영, 캔을 꽉 쥔다)';
    final s = summarizeDialogue(body);
    expect(s.speakers, ['민수', '지영']);
    // 지영의 둘째 줄은 윗줄 대사에 이어 붙는다
    expect(s.speeches, 3);
    expect(s.directions, 2);
  });

  test('이름과 콜론이 없는 본문은 인물이 없고 모두 지문이다', () {
    final s = summarizeDialogue('나는 늘 괜찮다고 말했어.\n아침에 눈을 뜰 때도.');
    expect(s.speakers, isEmpty);
    expect(s.speeches, 0);
    expect(s.directions, 1);
  });
}
