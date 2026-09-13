import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_filter.dart';

void main() {
  test('sourceOf는 작품명과 인물을 가운뎃점으로 잇고, 둘 다 없으면 null', () {
    expect(sourceOf('햄릿', '오필리어'), '햄릿 · 오필리어');
    expect(sourceOf('햄릿', null), '햄릿');
    expect(sourceOf(null, '니나'), '니나');
    expect(sourceOf(' ', ''), isNull);
    expect(sourceOf(null, null), isNull);
  });

  test('firstLineOf는 첫 비어있지 않은 줄', () {
    expect(firstLineOf('\n\n  괜찮다는 말은 참 편리하더라.\n다음 줄'), '괜찮다는 말은 참 편리하더라.');
    expect(firstLineOf('   \n  '), '');
  });

  test('normalized는 빈 칸을 null로 바꾸고 본문·메모를 다듬고 태그를 정리한다', () {
    const d = ScriptDraft(body: '  첫 줄\n둘째 줄 ', work: ' ', memo: '  오디션용  ', tags: [' 슬픔', '슬픔', '', '분노 ']);
    final r = d.normalized();
    expect(r.body, '첫 줄\n둘째 줄');
    expect(r.work, isNull);
    expect(r.memo, '오디션용');
    expect(r.tags, ['분노', '슬픔']);
    expect(const ScriptDraft(body: 'x', memo: '   ').normalized().memo, isNull);
  });

  test('enum 라벨', () {
    expect(Gender.values.map((g) => g.label), ['무관', '남', '여']);
    expect(AgeRange.fiftiesPlus.label, '50대 이상');
    expect(PracticeStatus.memorized.label, '다 외움');
  });

  test('ScriptFilter.copyWith는 nullable 값을 null로 되돌릴 수 있다', () {
    const f = ScriptFilter(gender: Gender.male, tag: '슬픔');
    expect(f.isActive, isTrue);
    final cleared = f.copyWith(gender: () => null, tag: () => null);
    expect(cleared.gender, isNull);
    expect(cleared.tag, isNull);
    expect(cleared.isActive, isFalse);
    expect(f.copyWith(query: '햄릿').gender, Gender.male);
  });
}
