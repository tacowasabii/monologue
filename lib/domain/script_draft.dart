import 'enums.dart';

const _titleLength = 20;

/// 본문의 첫 비어있지 않은 줄 앞부분을 제목으로 쓴다.
String defaultTitle(String body) {
  for (final line in body.split('\n')) {
    final t = line.trim();
    if (t.isNotEmpty) return t.length <= _titleLength ? t : t.substring(0, _titleLength);
  }
  return '제목 없음';
}

class ScriptDraft {
  const ScriptDraft({
    required this.title,
    required this.body,
    this.work,
    this.character,
    this.gender = Gender.any,
    this.ageRange = AgeRange.any,
    this.status = PracticeStatus.notStarted,
    this.favorite = false,
    this.tags = const [],
  });

  final String title;
  final String body;
  final String? work;
  final String? character;
  final Gender gender;
  final AgeRange ageRange;
  final PracticeStatus status;
  final bool favorite;
  final List<String> tags;

  /// 제목이 비면 본문으로 채우고, 빈 문자열은 null로, 태그는 trim·중복 제거·정렬한다.
  ScriptDraft withResolvedTitle() {
    String? blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    final cleanTags = {for (final t in tags) t.trim()}..remove('');
    return ScriptDraft(
      title: title.trim().isEmpty ? defaultTitle(body) : title.trim(),
      body: body.trim(),
      work: blankToNull(work),
      character: blankToNull(character),
      gender: gender,
      ageRange: ageRange,
      status: status,
      favorite: favorite,
      tags: cleanTags.toList()..sort(),
    );
  }
}
