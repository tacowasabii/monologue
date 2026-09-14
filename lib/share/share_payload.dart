import 'package:characters/characters.dart';

import '../data/script_repository.dart';
import '../domain/script_draft.dart';

/// [title] 폴백에 쓸 최대 글자 수(자모가 아니라 사람이 보는 글자 단위)
const _titleFallbackMaxChars = 40;

/// 링크로 주고받는 대본 내용. 메모, 사진, 연습 기록, 내 역할은 담지 않는다.
class SharePayload {
  const SharePayload({
    required this.body,
    this.work,
    this.dialogue = false,
    this.tags = const [],
    this.note,
    this.expiresAt,
  });

  factory SharePayload.fromDetail(ScriptDetail detail, {required bool includeNote}) {
    final s = detail.script;
    return SharePayload(
      body: s.body,
      work: s.work,
      dialogue: s.dialogue,
      tags: detail.tags,
      note: includeNote ? s.note : null,
    );
  }

  /// 서버 응답을 읽는다. 형식이 맞지 않으면 [FormatException].
  /// 예전 앱이 올린 대본에 남아 있는 성별·나이대 같은 칸은 읽지 않는다.
  factory SharePayload.fromJson(Object? json) {
    if (json is! Map<String, Object?>) throw const FormatException('share');
    final body = json['body'];
    if (body is! String || body.trim().isEmpty) throw const FormatException('body');
    final dialogue = json['dialogue'];
    if (dialogue is! bool) throw const FormatException('dialogue');
    final tags = json['tags'];
    if (tags is! List || tags.any((t) => t is! String)) throw const FormatException('tags');
    String? text(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) throw FormatException(key);
      return value.trim().isEmpty ? null : value;
    }

    final expires = json['expiresAt'];
    return SharePayload(
      body: body,
      work: text('work'),
      dialogue: dialogue,
      tags: tags.cast<String>(),
      note: text('note'),
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
    );
  }

  final String body;
  final String? work;
  final bool dialogue;
  final List<String> tags;
  final String? note;

  /// 서버에서 받은 대본에만 있다
  final DateTime? expiresAt;

  /// 작품명, 없으면 본문 첫 줄(너무 길면 40자로 자르고 … 을 붙인다)
  String get title => work ?? _truncated(firstLineOf(body));

  static String _truncated(String text) {
    final chars = text.characters;
    return chars.length > _titleFallbackMaxChars ? '${chars.take(_titleFallbackMaxChars)}…' : text;
  }

  Map<String, Object?> toJson() => {
        'v': 1,
        'work': work,
        'dialogue': dialogue,
        'body': body,
        'tags': tags,
        'note': note,
      };

  ScriptDraft toDraft() => ScriptDraft(
        body: body,
        work: work,
        dialogue: dialogue,
        tags: tags,
        note: note,
      );
}
