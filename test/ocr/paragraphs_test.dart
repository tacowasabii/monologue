import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ocr/assemble_text.dart';

OcrBlock b(double top, List<String> lines, {double left = 0, double? confidence, bool isChrome = false}) =>
    OcrBlock(top: top, left: left, lines: lines, confidence: confidence, isChrome: isChrome);

OcrLine l(String text, double top, {double left = 0, double height = 20, double? confidence}) =>
    OcrLine(text: text, top: top, left: left, height: height, confidence: confidence);

void main() {
  group('paragraphsOf', () {
    test('사진 번호와 읽는 순서대로 문단을 만든다', () {
      final paragraphs = paragraphsOf([
        [b(200, ['둘째 문단']), b(10, ['첫 문단'])],
        [b(0, ['셋째 문단'])],
      ]);
      expect(paragraphs.map((p) => (p.photoNumber, p.text)), [
        (1, '첫 문단'),
        (1, '둘째 문단'),
        (2, '셋째 문단'),
      ]);
    });

    test('글자가 없는 문단은 건너뛴다', () {
      expect(paragraphsOf([
        [b(0, ['   ']), b(50, ['본문'])],
      ]).map((p) => p.text), ['본문']);
    });

    test('문단 안의 줄은 공백으로 이어진다', () {
      expect(paragraphsOf([
        [b(0, ['나는 늘 괜찮다고', '말했어.'])],
      ]).single.text, '나는 늘 괜찮다고 말했어.');
    });

    test('확신도와 앱 화면 글자 표시를 그대로 전달한다', () {
      final p = paragraphsOf([
        [b(0, ['필기'], confidence: 0.31), b(60, ['좋아요 12개'], isChrome: true)],
      ]);
      expect(p.first.confidence, 0.31);
      expect(p.first.needsCheck, isTrue);
      expect(p.last.isChrome, isTrue);
    });
  });

  test('assembleText는 문단들을 빈 줄로 잇는다', () {
    expect(
      assembleText([
        [b(0, ['첫 문단']), b(60, ['둘째 문단'])],
      ]),
      '첫 문단\n\n둘째 문단',
    );
  });

  group('groupLines', () {
    test('문단의 확신도는 가장 낮은 줄을 따른다', () {
      final blocks = groupLines([
        l('인쇄된 대사', 100, confidence: 0.95),
        l('손으로 쓴 메모', 130, confidence: 0.34),
        l('다른 문단', 300, confidence: 0.9),
      ]);
      expect(blocks.map((x) => x.confidence), [0.34, 0.9]);
    });

    test('확신도를 주지 않는 줄만 있으면 문단 확신도도 없다', () {
      expect(groupLines([l('확신도 없음', 10)]).single.confidence, isNull);
    });

    // 실제 캡처에서 잰 값: 같은 문단은 줄 높이의 0.87~1.16배, 다른 문단은 1.26배 이상 벌어졌다
    test('줄 높이의 1.16배까지는 같은 문단으로 본다', () {
      final blocks = groupLines([
        l('나는 늘 괜찮다고 말했어. 아침에 눈을 뜰 때도,', 100, height: 25),
        l('버스에서 창밖을 볼 때도.', 154, height: 25), // 간격 29 = 1.16배
      ]);
      expect(blocks.single.lines.length, 2);
    });

    test('줄 높이의 1.2배를 넘으면 새 문단으로 나눈다', () {
      final blocks = groupLines([
        l('첫 문단', 100, height: 25),
        l('둘째 문단', 157, height: 25), // 간격 32 = 1.28배
      ]);
      expect(blocks.map((x) => x.lines), [
        ['첫 문단'],
        ['둘째 문단'],
      ]);
    });

    // 인스타 캡처에서는 좋아요 수·해시태그가 본문·캡션과 바싹 붙어 있어 그냥 두면 한 문단이 된다
    test('앱 화면 글자 줄은 간격이 좁아도 본문과 다른 문단으로 나뉜다', () {
      final blocks = groupLines([
        l('나는 늘 괜찮다고 말했어.', 100),
        l('좋아요 1,242개', 125),
        l('오디션 준비하며 적어 본 독백', 150),
      ]);
      expect(blocks.map((x) => x.lines), [
        ['나는 늘 괜찮다고 말했어.'],
        ['좋아요 1,242개'],
        ['오디션 준비하며 적어 본 독백'],
      ]);
      expect(blocks.map((x) => x.isChrome), [false, true, false]);
    });

    test('연달아 나오는 앱 화면 글자는 한 문단으로 묶인다', () {
      final blocks = groupLines([
        l('#독백 #연기 #오디션', 100),
        l('댓글 38개 모두 보기', 125),
        l('3일 전', 150),
      ]);
      expect(blocks.single.lines, ['#독백 #연기 #오디션', '댓글 38개 모두 보기', '3일 전']);
      expect(blocks.single.isChrome, isTrue);
    });
  });

  group('looksLikeChrome', () {
    const chrome = [
      '좋아요 1,242개',
      '댓글 38개 모두 보기',
      '답글 달기',
      '더 보기',
      '번역 보기',
      '팔로우',
      'kim_actor · 팔로우',
      'kim actor 팔로우', // 밑줄이 공백으로 읽히고 가운뎃점이 빠질 수 있다
      '3일 전',
      '2시간 전',
      '어제',
      '2026년 9월 11일',
      '@kim_actor',
      '#독백 #연기 #오디션',
      '프로필',
    ];
    const script = [
      '나는 늘 괜찮다고 말했어. 아침에 눈을 뜰 때도,',
      '괜찮다는 말은 참 편리하더라.',
      '더 보기만 하면 되는 줄 알았는데 아니더라.',
      '무대 왼쪽에서 천천히 등장',
      '햄릿: 사느냐 죽느냐',
      '오디션 준비하며 적어 본 독백',
      '네가 나를 따라오던 그 골목에서 나는 늘 팔로우라는 말을 떠올렸어',
    ];

    test('앱 화면 글자로 보이는 줄', () {
      for (final t in chrome) {
        expect(looksLikeChrome(t), isTrue, reason: t);
      }
    });

    test('대본 문장은 걸러내지 않는다', () {
      for (final t in script) {
        expect(looksLikeChrome(t), isFalse, reason: t);
      }
    });
  });
}
