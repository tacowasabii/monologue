import 'package:characters/characters.dart';

/// 줄바꿈 금지 문자(WORD JOINER). 화면에 보이지 않는다.
const _wordJoiner = '\u2060';

/// 한글은 글자 단위로 줄이 바뀌어 "때 / 도"처럼 단어가 갈라진다.
/// 단어 안의 글자 사이에 줄바꿈 금지 문자를 넣어 띄어쓰기 자리에서만 줄이 바뀌게 한다.
/// 보이지 않는 문자가 섞이므로 보여 주기만 하는 글에 쓰고, 입력칸에는 쓰지 않는다.
String keepWords(String text) {
  final out = StringBuffer();
  String? prev;
  // 이모지처럼 여러 코드로 된 글자를 가르지 않도록 사람이 보는 글자 단위로 돈다
  for (final c in text.characters) {
    if (prev != null && !_isSpace(prev) && !_isSpace(c)) out.write(_wordJoiner);
    out.write(c);
    prev = c;
  }
  return out.toString();
}

/// [keepWords]가 넣은 문자를 뺀다. 복사처럼 글이 화면 밖으로 나갈 때 쓴다.
String withoutWordJoiners(String text) => text.replaceAll(_wordJoiner, '');

bool _isSpace(String c) => c.trim().isEmpty;
