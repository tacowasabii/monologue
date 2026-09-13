import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_notes.dart';

void main() {
  test('normalized는 앞뒤 공백을 지우고 빈 값은 null로 바꾼다', () {
    const raw = ScriptNotes(situation: '  새벽, 부엌  ', objective: '   ', author: '체호프');
    final n = raw.normalized();
    expect(n.situation, '새벽, 부엌');
    expect(n.objective, isNull);
    expect(n.author, '체호프');
  });

  test('isEmpty는 공백만 있거나 아무것도 없을 때 true', () {
    expect(ScriptNotes.empty.isEmpty, isTrue);
    expect(const ScriptNotes(obstacle: '  ').isEmpty, isTrue);
    expect(const ScriptNotes(medium: ScriptMedium.play).isEmpty, isFalse);
  });

  test('JSON으로 바꿨다 되돌리면 같다', () {
    const n = ScriptNotes(
      situation: '상황',
      objective: '목표',
      obstacle: '장애물',
      author: '작가',
      medium: ScriptMedium.drama,
      sourceUrl: 'https://example.com',
      synopsis: '줄거리',
      sceneContext: '앞뒤',
    );
    expect(ScriptNotes.fromJson(n.toJson()), n);
    expect(ScriptNotes.fromJson(const {}), ScriptNotes.empty);
  });

  test('초안 정리는 형식을 유지하고 역할·노트도 정리한다', () {
    const d = ScriptDraft(body: '첫 줄', dialogue: true, myRole: ' 민수 ', notes: ScriptNotes(situation: ' 새벽 '));
    final r = d.normalized();
    expect(r.dialogue, isTrue);
    expect(r.myRole, '민수');
    expect(r.notes.situation, '새벽');
    expect(const ScriptDraft(body: 'x', myRole: '  ').normalized().myRole, isNull);
  });
}
