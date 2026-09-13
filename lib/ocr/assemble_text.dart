import 'dart:math';

/// 확신도가 이 값보다 낮은 문단은 "확인 필요"로 본다(보통 손글씨).
const lowConfidenceBelow = 0.5;

class OcrBlock {
  const OcrBlock({
    required this.top,
    required this.left,
    required this.lines,
    this.confidence,
    this.isChrome = false,
  });

  final double top;
  final double left;
  final List<String> lines;

  /// 문단 안에서 가장 낮은 줄의 확신도(0~1). 인식기가 주지 않으면 null.
  final double? confidence;

  /// 대본이 아니라 앱 화면 글자(좋아요 수·해시태그 등)로만 이뤄진 문단
  final bool isChrome;
}

/// 네이티브 인식기가 주는 한 줄. 좌표 단위는 플랫폼마다 달라도(픽셀·정규화) 비율만 쓰므로 상관없다.
class OcrLine {
  const OcrLine({
    required this.text,
    required this.top,
    required this.left,
    required this.height,
    this.confidence,
  });

  final String text;
  final double top;
  final double left;
  final double height;
  final double? confidence;

  double get bottom => top + height;
}

/// 사람에게 보여 줄 문단 하나. 어느 사진에서 나왔는지와 확신도를 함께 들고 다닌다.
class Paragraph {
  const Paragraph({
    required this.photoNumber,
    required this.text,
    this.confidence,
    this.isChrome = false,
  });

  final int photoNumber;
  final String text;
  final double? confidence;

  /// 앱 화면 글자로 보이는 문단. 골라내기 화면에서 꺼진 채로 시작한다.
  final bool isChrome;

  bool get needsCheck => confidence != null && confidence! < lowConfidenceBelow;
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

// 인스타·블로그 캡처에 딸려 오는 앱 화면 글자. 지우지 않고 체크만 꺼 두는 용도라 조금 넉넉해도 된다.
final _chromePatterns = <RegExp>[
  RegExp(r'^(좋아요|댓글|조회수|조회|답글|공유)\s*[\d,]+\s*개?$'),
  RegExp(r'^댓글\s*[\d,]+개?\s*모두\s*보기$'),
  RegExp(r'^(답글 달기|더 보기|번역 보기|공유하기|저장하기|팔로우|팔로잉|구독|메시지 보내기)$'),
  RegExp(r'^\d+(초|분|시간|일|주|개월|년)\s*전$'),
  RegExp(r'^(어제|오늘|방금|방금 전)$'),
  RegExp(r'^\d{4}년\s*\d{1,2}월\s*\d{1,2}일'),
  RegExp(r'^@[A-Za-z0-9._]+$'),
  RegExp(r'^#[^\s#]+(\s+#[^\s#]+)*$'),
  RegExp(r'^(홈|검색|릴스|프로필|알림|쇼핑|메뉴)$'),
  RegExp(r'·\s*(팔로우|팔로잉|구독)$'),
];

// "kim actor 팔로우"처럼 아이디와 버튼이 한 줄에 같이 잡히는 경우. 문장 속 낱말과 헷갈리지 않게 짧은 줄에만 적용한다.
final _chromeButtonTail = RegExp(r'(팔로우|팔로잉|구독)$');

/// 대본이 아니라 앱 화면 글자로 보이는 한 줄인지. 골라내기 화면의 기본 체크를 정할 때만 쓴다.
bool looksLikeChrome(String text) {
  final t = text.replaceAll(_spaces, ' ').trim();
  if (t.isEmpty) return false;
  if (t.length <= 20 && _chromeButtonTail.hasMatch(t)) return true;
  return _chromePatterns.any((p) => p.hasMatch(t));
}

bool _isChromeRow(List<OcrLine> row) => looksLikeChrome(row.map((l) => l.text).join(' '));

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
  if (rows.isEmpty) return const [];
  for (final row in rows) {
    row.sort((a, b) => a.left.compareTo(b.left));
  }

  // 간격이 벌어지면 새 문단. 앱 화면 글자와 본문은 붙어 있어도 섞지 않는다.
  final blocks = <OcrBlock>[];
  double bottomOf(List<OcrLine> row) => row.map((l) => l.bottom).reduce(max);
  var current = [...rows.first];
  var currentChrome = _isChromeRow(rows.first);
  var currentBottom = bottomOf(rows.first);
  for (final row in rows.skip(1)) {
    final rowTop = row.map((l) => l.top).reduce(min);
    final rowChrome = _isChromeRow(row);
    if (rowTop - currentBottom > medianHeight || rowChrome != currentChrome) {
      blocks.add(_toBlock(current, currentChrome));
      current = [...row];
      currentChrome = rowChrome;
      currentBottom = bottomOf(row);
    } else {
      current.addAll(row);
      currentBottom = max(currentBottom, bottomOf(row));
    }
  }
  blocks.add(_toBlock(current, currentChrome));
  return blocks;
}

OcrBlock _toBlock(List<OcrLine> lines, bool isChrome) {
  // 손글씨가 한 줄만 섞여도 문단이 드러나도록 가장 낮은 확신도를 쓴다
  final confidences = [for (final l in lines) if (l.confidence != null) l.confidence!];
  return OcrBlock(
    top: lines.map((l) => l.top).reduce(min),
    left: lines.map((l) => l.left).reduce(min),
    lines: [for (final l in lines) l.text],
    confidence: confidences.isEmpty ? null : confidences.reduce(min),
    isChrome: isChrome,
  );
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

/// 이미지별 인식 블록을 읽는 순서대로 문단 목록으로 만든다(사진 번호는 1부터).
List<Paragraph> paragraphsOf(List<List<OcrBlock>> pages) {
  final paragraphs = <Paragraph>[];
  for (var i = 0; i < pages.length; i++) {
    final sorted = [...pages[i]]..sort((a, b) => _readingOrder(a.top, a.left, b.top, b.left));
    for (final block in sorted) {
      final text = joinLines(block.lines);
      if (text.isEmpty) continue;
      paragraphs.add(Paragraph(
        photoNumber: i + 1,
        text: text,
        confidence: block.confidence,
        isChrome: block.isChrome,
      ));
    }
  }
  return paragraphs;
}

/// 문단들을 빈 줄로 이어 본문 하나로 만든다.
String assembleText(List<List<OcrBlock>> pages) => textOf(paragraphsOf(pages));

/// 고른 문단만 본문으로 잇는다.
String textOf(List<Paragraph> paragraphs) => paragraphs.map((p) => p.text).join('\n\n');
