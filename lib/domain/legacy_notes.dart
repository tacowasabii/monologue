/// 노트가 자유 글 한 칸이 되기 전(DB 버전 6·7, 백업 version 2)에 나뉘어 있던 노트 칸과 그 제목.
/// 키는 백업 JSON에 쓰던 이름이다.
const _legacyLabels = {
  'situation': '상황',
  'objective': '원하는 것',
  'obstacle': '가로막는 것',
  'author': '작가',
  'medium': '매체',
  'sourceUrl': '출처 링크',
  'synopsis': '작품 줄거리',
  'sceneContext': '이 장면 앞뒤',
};

const _mediumLabels = {
  'film': '영화',
  'drama': '드라마',
  'play': '연극',
  'musical': '뮤지컬',
  'original': '창작',
  'other': '기타',
};

/// 예전 노트 칸들을 "상황: …"처럼 제목을 붙여 원래 칸 차례대로 한 글로 합친다. 적은 칸이 없으면 null.
String? legacyNoteText(Map<String, Object?> fields) {
  final parts = <String>[];
  for (final MapEntry(key: key, value: label) in _legacyLabels.entries) {
    final raw = fields[key];
    if (raw is! String) continue;
    final text = key == 'medium' ? (_mediumLabels[raw] ?? raw) : raw.trim();
    if (text.isNotEmpty) parts.add('$label: $text');
  }
  return parts.isEmpty ? null : parts.join('\n\n');
}
