import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/share/sent_link.dart';
import 'package:monologue/share/share_payload.dart';

void main() {
  test('서버로 보낼 JSON은 버전과 enum 이름을 쓴다', () {
    const payload = SharePayload(
      body: '엄마: 뭐 해?',
      work: '새벽 세 시의 부엌',
      dialogue: true,
      gender: Gender.female,
      ageRange: AgeRange.fiftiesPlus,
      tags: ['가족'],
    );
    expect(payload.toJson(), {
      'v': 1,
      'work': '새벽 세 시의 부엌',
      'dialogue': true,
      'body': '엄마: 뭐 해?',
      'gender': 'female',
      'ageRange': 'fiftiesPlus',
      'tags': ['가족'],
      'note': null,
    });
  });

  test('받은 JSON을 읽어 새 대본 초안으로 만든다', () {
    final payload = SharePayload.fromJson({
      'v': 1,
      'work': '햄릿',
      'dialogue': false,
      'body': '사느냐 죽느냐',
      'gender': 'male',
      'ageRange': 'twenties',
      'tags': ['고전'],
      'note': '고뇌',
      'createdAt': '2026-09-14T12:00:00.000Z',
      'expiresAt': '2026-09-21T12:00:00.000Z',
    });
    expect(payload.expiresAt, DateTime.utc(2026, 9, 21, 12));
    final draft = payload.toDraft();
    expect(draft.work, '햄릿');
    expect(draft.body, '사느냐 죽느냐');
    expect(draft.gender, Gender.male);
    expect(draft.ageRange, AgeRange.twenties);
    expect(draft.tags, ['고전']);
    expect(draft.note, '고뇌');
    expect(draft.dialogue, isFalse);
    expect(draft.memo, isNull);
    expect(draft.myRole, isNull);
  });

  test('모르는 성별·나이대는 무관으로, 빈 작품명·노트는 없음으로 읽는다', () {
    final payload = SharePayload.fromJson(
        {'body': '대사', 'dialogue': false, 'tags': <Object?>[], 'gender': 'x', 'ageRange': 'y', 'work': ' ', 'note': ''});
    expect(payload.gender, Gender.any);
    expect(payload.ageRange, AgeRange.any);
    expect(payload.work, isNull);
    expect(payload.note, isNull);
    expect(payload.title, '대사');
  });

  test('작품명이 없으면 본문 첫 줄이 제목이 되고, 짧으면 그대로 쓴다', () {
    const payload = SharePayload(body: '짧은 첫 줄\n나머지', dialogue: false);
    expect(payload.title, '짧은 첫 줄');
  });

  test('작품명이 없고 본문 첫 줄이 40자를 넘으면 40자로 자르고 …을 붙인다', () {
    final line41 = '가' * 41;
    final payload = SharePayload(body: '$line41\n나머지', dialogue: false);
    expect(payload.title, '${'가' * 40}…');
    expect(payload.title.characters.length, 41); // 40자 + …
  });

  test('work가 있으면 아무리 길어도 그대로 쓴다', () {
    final longWork = '가' * 50;
    const body = '본문';
    final payload = SharePayload(body: body, work: '가' * 50, dialogue: false);
    expect(payload.title, longWork);
  });

  test('형식이 틀리면 FormatException', () {
    expect(() => SharePayload.fromJson('x'), throwsFormatException);
    expect(() => SharePayload.fromJson({'body': ' ', 'dialogue': false, 'tags': <Object?>[]}), throwsFormatException);
    expect(() => SharePayload.fromJson({'body': 'a', 'dialogue': 'no', 'tags': <Object?>[]}), throwsFormatException);
    expect(() => SharePayload.fromJson({'body': 'a', 'dialogue': false, 'tags': [1]}), throwsFormatException);
  });

  test('보낸 링크 기록은 JSON으로 저장했다 읽을 수 있고, 망가진 값은 버린다', () {
    final link = SentLink(
      id: 'A' * 22,
      url: 'https://tacowasabii.vercel.app/monologue/s/${'A' * 22}',
      deleteToken: 'secret',
      title: '햄릿',
      expiresAt: DateTime.utc(2026, 9, 21, 12),
    );
    final back = SentLink.tryFromJson(link.toJson())!;
    expect(back.id, link.id);
    expect(back.url, link.url);
    expect(back.deleteToken, 'secret');
    expect(back.title, '햄릿');
    expect(back.expiresAt, link.expiresAt);
    expect(SentLink.tryFromJson({'id': 1}), isNull);
  });

  test('남은 날짜는 올림해서 1~7일로 센다', () {
    final now = DateTime.utc(2026, 9, 14, 12);
    expect(daysLeft(now.add(const Duration(days: 7)), now), 7);
    expect(daysLeft(now.add(const Duration(days: 3)), now), 3);
    expect(daysLeft(now.add(const Duration(hours: 1)), now), 1);
    expect(daysLeft(now.subtract(const Duration(hours: 1)), now), 1);
  });
}
