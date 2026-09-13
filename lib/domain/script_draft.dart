import 'enums.dart';
import 'script_notes.dart';

/// 본문의 첫 비어있지 않은 줄. 없으면 빈 문자열.
String firstLineOf(String body) {
  for (final line in body.split('\n')) {
    final t = line.trim();
    if (t.isNotEmpty) return t;
  }
  return '';
}

class ScriptDraft {
  const ScriptDraft({
    required this.body,
    this.work,
    this.memo,
    this.gender = Gender.any,
    this.ageRange = AgeRange.any,
    this.status = PracticeStatus.notStarted,
    this.favorite = false,
    this.tags = const [],
    this.dialogue = false,
    this.myRole,
    this.notes = ScriptNotes.empty,
  });

  final String body;
  final String? work;
  final String? memo;
  final Gender gender;
  final AgeRange ageRange;
  final PracticeStatus status;
  final bool favorite;
  final List<String> tags;
  final bool dialogue;

  /// 대화 대본에서 강조해 읽을 인물 이름
  final String? myRole;
  final ScriptNotes notes;

  /// 빈 칸은 null로, 본문·메모는 앞뒤 공백을 다듬고, 태그는 trim·중복 제거·정렬한다.
  ScriptDraft normalized() {
    String? blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    final cleanTags = {for (final t in tags) t.trim()}..remove('');
    return ScriptDraft(
      body: body.trim(),
      work: blankToNull(work),
      memo: blankToNull(memo),
      gender: gender,
      ageRange: ageRange,
      status: status,
      favorite: favorite,
      tags: cleanTags.toList()..sort(),
      dialogue: dialogue,
      myRole: blankToNull(myRole),
      notes: notes.normalized(),
    );
  }
}
