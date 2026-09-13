import 'enums.dart';

/// 대본 분석(상황·원하는 것·가로막는 것)과 작품 맥락. 모두 선택 입력이다. 자유 메모는 대본의 `memo` 칸을 쓴다.
class ScriptNotes {
  const ScriptNotes({
    this.situation,
    this.objective,
    this.obstacle,
    this.author,
    this.medium,
    this.sourceUrl,
    this.synopsis,
    this.sceneContext,
  });

  static const empty = ScriptNotes();

  /// 누가·어디서·언제·직전에 무슨 일
  final String? situation;
  final String? objective;
  final String? obstacle;
  final String? author;
  final ScriptMedium? medium;
  final String? sourceUrl;
  final String? synopsis;
  final String? sceneContext;

  bool get isEmpty =>
      medium == null &&
      [situation, objective, obstacle, author, sourceUrl, synopsis, sceneContext]
          .every((t) => t == null || t.trim().isEmpty);

  ScriptNotes normalized() {
    String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    return ScriptNotes(
      situation: clean(situation),
      objective: clean(objective),
      obstacle: clean(obstacle),
      author: clean(author),
      medium: medium,
      sourceUrl: clean(sourceUrl),
      synopsis: clean(synopsis),
      sceneContext: clean(sceneContext),
    );
  }

  Map<String, Object?> toJson() => {
        'situation': situation,
        'objective': objective,
        'obstacle': obstacle,
        'author': author,
        'medium': medium?.name,
        'sourceUrl': sourceUrl,
        'synopsis': synopsis,
        'sceneContext': sceneContext,
      };

  factory ScriptNotes.fromJson(Map<String, Object?> j) => ScriptNotes(
        situation: j['situation'] as String?,
        objective: j['objective'] as String?,
        obstacle: j['obstacle'] as String?,
        author: j['author'] as String?,
        medium: switch (j['medium']) {
          final String name => ScriptMedium.values.byName(name),
          _ => null,
        },
        sourceUrl: j['sourceUrl'] as String?,
        synopsis: j['synopsis'] as String?,
        sceneContext: j['sceneContext'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is ScriptNotes &&
      other.situation == situation &&
      other.objective == objective &&
      other.obstacle == obstacle &&
      other.author == author &&
      other.medium == medium &&
      other.sourceUrl == sourceUrl &&
      other.synopsis == synopsis &&
      other.sceneContext == sceneContext;

  @override
  int get hashCode => Object.hash(situation, objective, obstacle, author, medium, sourceUrl, synopsis, sceneContext);
}
