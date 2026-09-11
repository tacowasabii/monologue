import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_filter.dart';

void main() {
  test('defaultTitle은 첫 비어있지 않은 줄의 앞 20자', () {
    expect(defaultTitle('\n\n  괜찮다는 말은 참 편리하더라. 그 한마디면\n다음 줄'), '괜찮다는 말은 참 편리하더라. 그 한');
    expect(defaultTitle('짧은 줄\n다음'), '짧은 줄');
    expect(defaultTitle('   \n  '), '제목 없음');
  });

  test('withResolvedTitle은 제목이 비었을 때만 채우고 태그를 정리한다', () {
    const d = ScriptDraft(title: '  ', body: '첫 줄\n둘째 줄', work: ' ', tags: [' 슬픔', '슬픔', '', '분노 ']);
    final r = d.withResolvedTitle();
    expect(r.title, '첫 줄');
    expect(r.work, isNull);
    expect(r.tags, ['분노', '슬픔']);
    expect(const ScriptDraft(title: '햄릿', body: 'x').withResolvedTitle().title, '햄릿');
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
