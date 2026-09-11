class OcrBlock {
  const OcrBlock({required this.top, required this.left, required this.lines});

  final double top;
  final double left;
  final List<String> lines;
}

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
    final sorted = [...blocks]
      ..sort((a, b) {
        final byTop = a.top.compareTo(b.top);
        return byTop != 0 ? byTop : a.left.compareTo(b.left);
      });
    final text = sorted.map((b) => joinLines(b.lines)).where((t) => t.isNotEmpty).join('\n\n');
    if (text.isNotEmpty) pageTexts.add(text);
  }
  return pageTexts.join('\n\n');
}
