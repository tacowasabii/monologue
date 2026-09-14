/// 대본의 한 덩어리. [speaker]가 있으면 그 인물의 대사, [direction]이면 지문이다.
class DialogueLine {
  const DialogueLine({this.speaker, required this.text, this.direction = false});

  final String? speaker;
  final String text;
  final bool direction;

  @override
  bool operator ==(Object other) =>
      other is DialogueLine && other.speaker == speaker && other.text == text && other.direction == direction;

  @override
  int get hashCode => Object.hash(speaker, text, direction);

  @override
  String toString() => direction ? 'note($text)' : 'say($speaker, $text)';
}

// 이름은 1~12자, 콜론은 반각·전각 모두
final _speakerLine = RegExp(r'^([^:：]{1,12}?)\s*[:：]\s*(.*)$');
final _digitsOnly = RegExp(r'^\d+$');

(String, String)? _splitSpeaker(String line) {
  final m = _speakerLine.firstMatch(line);
  if (m == null) return null;
  final name = m.group(1)!.trim();
  if (name.isEmpty || _digitsOnly.hasMatch(name) || name.toLowerCase().startsWith('http')) return null;
  return (name, m.group(2)!.trim());
}

/// 평문 본문을 대사·지문으로 나눈다.
/// - `이름: 대사` 줄은 그 인물의 대사를 시작한다(이름만 있고 대사가 비면 다음 줄이 대사가 된다).
/// - 이름 없는 줄은 빈 줄이 나오기 전까지 바로 앞 덩어리에 이어 붙는다.
/// - 줄 전체가 `(…)`이면 지문이고, 지문 다음 이름 없는 줄은 그 전 인물의 대사다.
/// - 빈 줄 뒤에 이름 없이 오는 줄은 지문이다.
List<DialogueLine> parseDialogue(String body) {
  final out = <DialogueLine>[];
  String? current;
  var joinable = false; // 바로 앞 덩어리에 이어 붙일 수 있는지

  void appendToLast(String line) {
    final last = out.removeLast();
    out.add(DialogueLine(
      speaker: last.speaker,
      text: last.text.isEmpty ? line : '${last.text}\n$line',
      direction: last.direction,
    ));
  }

  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      current = null;
      joinable = false;
      continue;
    }
    if (line.startsWith('(') && line.endsWith(')')) {
      out.add(DialogueLine(text: line, direction: true));
      joinable = false;
      continue;
    }
    final split = _splitSpeaker(line);
    if (split != null) {
      current = split.$1;
      out.add(DialogueLine(speaker: split.$1, text: split.$2));
    } else if (joinable) {
      appendToLast(line);
    } else if (current != null) {
      out.add(DialogueLine(speaker: current, text: line));
    } else {
      out.add(DialogueLine(text: line, direction: true));
    }
    joinable = true;
  }
  return out;
}

bool looksLikeDialogue(String body) =>
    body.split('\n').where((l) => _splitSpeaker(l.trim()) != null).length >= 2;

List<String> speakersOf(List<DialogueLine> lines) => [
      ...{
        for (final l in lines)
          if (l.speaker != null) l.speaker!,
      },
    ];

/// 대화 본문에서 알아낸 인물(나온 차례대로)과 대사·지문 덩어리 수
typedef DialogueSummary = ({List<String> speakers, int speeches, int directions});

/// 편집 화면에서 대화 형식에 맞게 적었는지 보여 줄 때 쓴다.
DialogueSummary summarizeDialogue(String body) {
  final lines = parseDialogue(body);
  return (
    speakers: speakersOf(lines),
    speeches: lines.where((l) => l.speaker != null).length,
    directions: lines.where((l) => l.direction).length,
  );
}
