import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:monologue/share/sent_link.dart';
import 'package:monologue/share/share_client.dart';
import 'package:monologue/share/share_payload.dart';

http.Response jsonResponse(Object? body, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  final id = 'A' * 22;
  const payload = SharePayload(body: '사느냐 죽느냐', work: '햄릿', tags: ['고전']);

  test('올리면 링크 기록을 돌려준다', () async {
    late http.Request sent;
    final client = ShareClient(MockClient((request) async {
      sent = request;
      return jsonResponse({
        'id': id,
        'url': 'https://tacowasabii.vercel.app/monologue/s/$id',
        'deleteToken': 'secret',
        'expiresAt': '2026-09-21T12:00:00.000Z',
      }, 201);
    }));

    final result = await client.upload(payload);

    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://tacowasabii.vercel.app/api/monologue/shares');
    expect(jsonDecode(sent.body), payload.toJson());
    final link = (result as ShareOk<SentLink>).value;
    expect(link.id, id);
    expect(link.deleteToken, 'secret');
    expect(link.title, '햄릿');
    expect(link.expiresAt, DateTime.utc(2026, 9, 21, 12));
  });

  test('올리기 실패는 이유별로 나눈다', () async {
    Future<ShareResult<SentLink>> uploadWith(int status) =>
        ShareClient(MockClient((_) async => http.Response('', status))).upload(payload);
    expect(await uploadWith(413), isA<ShareTooLarge<SentLink>>());
    expect(await uploadWith(429), isA<ShareRateLimited<SentLink>>());
    expect(await uploadWith(503), isA<ShareFailed<SentLink>>());
    final offline = ShareClient(MockClient((_) async => throw http.ClientException('offline')));
    expect(await offline.upload(payload), isA<ShareFailed<SentLink>>());
  });

  test('가져오기는 한글 본문을 그대로 읽고, 없으면 ShareMissing', () async {
    final client = ShareClient(MockClient((request) async {
      expect(request.url.path, '/api/monologue/shares/$id');
      return jsonResponse({'v': 1, 'work': null, 'dialogue': true, 'body': '민수: 안녕', 'gender': 'any', 'ageRange': 'any', 'tags': <String>[], 'note': null}, 200);
    }));
    final result = await client.fetch(id);
    expect((result as ShareOk<SharePayload>).value.body, '민수: 안녕');

    expect(await ShareClient(MockClient((_) async => http.Response('', 404))).fetch(id), isA<ShareMissing<SharePayload>>());
    expect(await ShareClient(MockClient((_) async => http.Response('{', 200))).fetch(id), isA<ShareFailed<SharePayload>>());
  });

  test('지우기는 비밀값을 Bearer로 보내고, 없는 링크는 ShareMissing', () async {
    final link = SentLink(id: id, url: 'u', deleteToken: 'secret', title: 't', expiresAt: DateTime.utc(2026, 9, 21));
    late http.Request sent;
    final ok = await ShareClient(MockClient((request) async {
      sent = request;
      return http.Response('', 204);
    })).delete(link);
    expect(ok, isA<ShareOk<void>>());
    expect(sent.method, 'DELETE');
    expect(sent.url.path, '/api/monologue/shares/$id');
    expect(sent.headers['Authorization'], 'Bearer secret');

    expect(await ShareClient(MockClient((_) async => http.Response('', 404))).delete(link), isA<ShareMissing<void>>());
    expect(await ShareClient(MockClient((_) async => http.Response('', 403))).delete(link), isA<ShareFailed<void>>());
  });
}
