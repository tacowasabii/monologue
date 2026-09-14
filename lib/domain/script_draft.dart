import 'enums.dart';

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
    this.status = PracticeStatus.notStarted,
    this.favorite = false,
    this.tags = const [],
    this.collectionIds = const [],
    this.dialogue = false,
    this.myRole,
    this.note,
  });

  final String body;
  final String? work;
  final String? memo;
  final PracticeStatus status;
  final bool favorite;
  final List<String> tags;
  final List<int> collectionIds;
  final bool dialogue;

  /// 대화 대본에서 강조해 읽을 인물 이름
  final String? myRole;

  /// 대본에 대해 형식 없이 자유롭게 적은 노트
  final String? note;

  /// 빈 칸은 null로, 본문·메모·노트는 앞뒤 공백을 다듬고, 태그·모음은 중복 제거·정렬한다.
  ScriptDraft normalized() {
    String? blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    final cleanTags = {for (final t in tags) t.trim()}..remove('');
    return ScriptDraft(
      body: body.trim(),
      work: blankToNull(work),
      memo: blankToNull(memo),
      status: status,
      favorite: favorite,
      tags: cleanTags.toList()..sort(),
      collectionIds: {...collectionIds}.toList()..sort(),
      dialogue: dialogue,
      myRole: blankToNull(myRole),
      note: blankToNull(note),
    );
  }

  /// 모음만 바꾼 사본. 백업 복원에서 모음 이름을 id로 바꾼 뒤 쓴다.
  ScriptDraft withCollectionIds(List<int> ids) => ScriptDraft(
        body: body,
        work: work,
        memo: memo,
        status: status,
        favorite: favorite,
        tags: tags,
        collectionIds: ids,
        dialogue: dialogue,
        myRole: myRole,
        note: note,
      );
}
