import 'enums.dart';

/// 작품명과 인물을 가운뎃점으로 잇는다. 둘 다 비어 있으면 null.
String? sourceOf(String? work, String? character) {
  final parts = [work, character].map((e) => e?.trim() ?? '').where((e) => e.isNotEmpty);
  return parts.isEmpty ? null : parts.join(' · ');
}

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
    this.character,
    this.memo,
    this.gender = Gender.any,
    this.ageRange = AgeRange.any,
    this.status = PracticeStatus.notStarted,
    this.favorite = false,
    this.tags = const [],
  });

  final String body;
  final String? work;
  final String? character;
  final String? memo;
  final Gender gender;
  final AgeRange ageRange;
  final PracticeStatus status;
  final bool favorite;
  final List<String> tags;

  /// 빈 칸은 null로, 본문·메모는 앞뒤 공백을 다듬고, 태그는 trim·중복 제거·정렬한다.
  ScriptDraft normalized() {
    String? blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    final cleanTags = {for (final t in tags) t.trim()}..remove('');
    return ScriptDraft(
      body: body.trim(),
      work: blankToNull(work),
      character: blankToNull(character),
      memo: blankToNull(memo),
      gender: gender,
      ageRange: ageRange,
      status: status,
      favorite: favorite,
      tags: cleanTags.toList()..sort(),
    );
  }
}
