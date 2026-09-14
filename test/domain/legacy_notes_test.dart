import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/legacy_notes.dart';
import 'package:monologue/domain/script_draft.dart';

void main() {
  test('예전 노트 칸은 적은 칸만 제목을 붙여 원래 차례대로 한 글로 합친다', () {
    expect(
      legacyNoteText({
        'situation': ' 새벽, 부엌 ',
        'objective': '  ',
        'author': '체호프',
        'medium': 'play',
        'sourceUrl': 'https://example.com',
        'sceneContext': '직전에 크게 다퉜다',
      }),
      '상황: 새벽, 부엌\n\n작가: 체호프\n\n매체: 연극\n\n출처 링크: https://example.com\n\n이 장면 앞뒤: 직전에 크게 다퉜다',
    );
    expect(legacyNoteText(const {}), isNull);
    expect(legacyNoteText({'situation': ' ', 'medium': null}), isNull);
  });

  test('초안 정리는 형식을 유지하고 역할·노트의 앞뒤 공백을 지운다', () {
    const d = ScriptDraft(body: '첫 줄', dialogue: true, myRole: ' 민수 ', note: '  새벽\n\n떠오르는 생각  ');
    final r = d.normalized();
    expect(r.dialogue, isTrue);
    expect(r.myRole, '민수');
    expect(r.note, '새벽\n\n떠오르는 생각');
    final blank = const ScriptDraft(body: 'x', myRole: '  ', note: ' \n ').normalized();
    expect(blank.myRole, isNull);
    expect(blank.note, isNull);
  });
}
