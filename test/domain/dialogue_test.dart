import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/dialogue.dart';

DialogueLine say(String who, String text) => DialogueLine(speaker: who, text: text);
DialogueLine note(String text) => DialogueLine(text: text, direction: true);

void main() {
  test('이름: 대사 줄을 인물별로 나눈다', () {
    expect(parseDialogue('민수: 왜 그랬어?\n지영: 몰라.'), [say('민수', '왜 그랬어?'), say('지영', '몰라.')]);
  });

  test('이름 없는 줄은 빈 줄 전까지 앞 인물 대사로 이어진다', () {
    expect(parseDialogue('민수: 왜\n그랬어?\n\n지영: 몰라'), [say('민수', '왜\n그랬어?'), say('지영', '몰라')]);
  });

  test('괄호로만 된 줄은 지문이고, 지문 뒤 이름 없는 줄은 같은 인물 대사다', () {
    expect(parseDialogue('(문이 열린다)\n민수 : 누구야?\n(웃으며)\n나야'), [
      note('(문이 열린다)'),
      say('민수', '누구야?'),
      note('(웃으며)'),
      say('민수', '나야'),
    ]);
  });

  test('빈 줄 뒤에 이름 없이 오는 줄은 지문이다', () {
    expect(parseDialogue('민수: 가\n\n무대가 어두워진다\n조명이 꺼진다'), [
      say('민수', '가'),
      note('무대가 어두워진다\n조명이 꺼진다'),
    ]);
  });

  test('전각 콜론은 대사로, 숫자·링크·긴 문장 앞 콜론은 대사로 보지 않는다', () {
    expect(parseDialogue('지영：응\n10:30\nhttps://a.b'), [say('지영', '응\n10:30\nhttps://a.b')]);
    expect(parseDialogue('이것은 열세 글자를 넘는 긴 문장: 끝'), [note('이것은 열세 글자를 넘는 긴 문장: 끝')]);
  });

  test('이름만 있는 줄 다음 줄은 그 인물 대사가 된다', () {
    expect(parseDialogue('민수:\n왜 그랬어?'), [say('민수', '왜 그랬어?')]);
  });

  test('looksLikeDialogue는 대사 줄이 2줄 이상일 때 true', () {
    expect(looksLikeDialogue('민수: 가\n지영: 와'), isTrue);
    expect(looksLikeDialogue('시간: 새벽 세 시\n나는 늘 괜찮다고 말했어.'), isFalse);
  });

  test('speakersOf는 처음 나온 순서로 중복 없이 준다', () {
    expect(speakersOf(parseDialogue('지영: 1\n민수: 2\n지영: 3')), ['지영', '민수']);
  });
}
