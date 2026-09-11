import 'dart:math';

class OcrBlock {
  const OcrBlock({required this.top, required this.left, required this.lines});

  final double top;
  final double left;
  final List<String> lines;
}

/// 네이티브 인식기가 주는 한 줄. 좌표 단위는 플랫폼마다 달라도(픽셀·정규화) 비율만 쓰므로 상관없다.
class OcrLine {
  const OcrLine({required this.text, required this.top, required this.left, required this.height});

  final String text;
  final double top;
  final double left;
  final double height;

  double get bottom => top + height;
}

int _readingOrder(double aTop, double aLeft, double bTop, double bLeft) {
  final byTop = aTop.compareTo(bTop);
  return byTop != 0 ? byTop : aLeft.compareTo(bLeft);
}

// 캡처 맨 위 상태바를 이루는 조각: 시각, 오전/오후, 배터리 숫자·%, 통신 방식, 통신사
final _statusBarToken = RegExp(
  r'^(\d{1,2}:\d{2}|오전|오후|\d{1,3}%?|%|5G\+?|4G|3G|LTE\+?|LTE-A|Wi-?Fi|VoLTE|SKT|KT|LG|U\+|LGU\+)$',
  caseSensitive: false,
);
final _statusBarAnchor = RegExp(r'\d{1,2}:\d{2}|\d\s*%');

/// 시각이나 배터리 표시가 있고, 모든 조각이 상태바 조각일 때만 상태바로 본다.
bool _isStatusBarRow(List<OcrLine> row) {
  final text = row.map((l) => l.text).join(' ');
  final tokens = text.split(_spaces).where((t) => t.isNotEmpty);
  return _statusBarAnchor.hasMatch(text) && tokens.every(_statusBarToken.hasMatch);
}

/// 줄을 읽는 순서로 정렬하고, 앞 줄과의 간격이 줄 높이(중앙값)보다 크면 새 문단으로 나눈다.
List<OcrBlock> groupLines(List<OcrLine> lines) {
  final kept = lines.where((l) => l.text.trim().isNotEmpty).toList()..sort((a, b) => a.top.compareTo(b.top));
  if (kept.isEmpty) return const [];

  final heights = kept.map((l) => l.height).toList()..sort();
  final medianHeight = heights[heights.length ~/ 2];

  // 인물명과 대사처럼 한 줄이 따로 인식되면 글꼴 차이로 top이 조금 어긋난다.
  // 행 첫 줄과 top 차이가 줄 높이 절반 이내면 같은 행으로 본다.
  final rows = <List<OcrLine>>[];
  for (final line in kept) {
    if (rows.isNotEmpty && line.top - rows.last.first.top <= medianHeight / 2) {
      rows.last.add(line);
    } else {
      rows.add([line]);
    }
  }
  // 휴대폰 캡처 맨 위의 상태바는 대본이 아니다(맨 윗 행에만 적용)
  if (_isStatusBarRow(rows.first)) rows.removeAt(0);
  final ordered = [
    for (final row in rows) ...(row..sort((a, b) => a.left.compareTo(b.left))),
  ];
  if (ordered.isEmpty) return const [];

  final blocks = <OcrBlock>[];
  var current = [ordered.first];
  var currentBottom = ordered.first.bottom;
  for (final line in ordered.skip(1)) {
    if (line.top - currentBottom > medianHeight) {
      blocks.add(_toBlock(current));
      current = [line];
      currentBottom = line.bottom;
    } else {
      current.add(line);
      currentBottom = max(currentBottom, line.bottom);
    }
  }
  blocks.add(_toBlock(current));
  return blocks;
}

OcrBlock _toBlock(List<OcrLine> lines) => OcrBlock(
      top: lines.map((l) => l.top).reduce(min),
      left: lines.map((l) => l.left).reduce(min),
      lines: [for (final l in lines) l.text],
    );

final _spaces = RegExp(r'\s+');

/// 화면 폭 때문에 생긴 줄바꿈을 이어붙인다.
String joinLines(List<String> lines) {
  final buf = StringBuffer();
  for (final raw in lines) {
    final line = raw.replaceAll(_spaces, ' ').trim();
    if (line.isEmpty) continue;
    if (buf.isNotEmpty && !buf.toString().endsWith('-')) buf.write(' ');
    buf.write(line);
  }
  return buf.toString();
}

/// 이미지별 인식 블록을 읽는 순서대로 본문 하나로 만든다.
String assembleText(List<List<OcrBlock>> pages) {
  final pageTexts = <String>[];
  for (final blocks in pages) {
    final sorted = [...blocks]..sort((a, b) => _readingOrder(a.top, a.left, b.top, b.left));
    final text = sorted.map((b) => joinLines(b.lines)).where((t) => t.isNotEmpty).join('\n\n');
    if (text.isNotEmpty) pageTexts.add(text);
  }
  return pageTexts.join('\n\n');
}
