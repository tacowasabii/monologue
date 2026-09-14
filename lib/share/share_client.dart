import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sent_link.dart';
import 'share_link.dart';
import 'share_payload.dart';

sealed class ShareResult<T> {
  const ShareResult();
}

class ShareOk<T> extends ShareResult<T> {
  const ShareOk(this.value);
  final T value;
}

/// 링크가 없거나 7일이 지났거나 보낸 사람이 지웠다
class ShareMissing<T> extends ShareResult<T> {
  const ShareMissing();
}

class ShareTooLarge<T> extends ShareResult<T> {
  const ShareTooLarge();
}

class ShareRateLimited<T> extends ShareResult<T> {
  const ShareRateLimited();
}

/// 연결 실패, 서버 오류, 알아볼 수 없는 응답
class ShareFailed<T> extends ShareResult<T> {
  const ShareFailed();
}

class ShareClient {
  ShareClient(this._http, {Uri? base}) : _base = base ?? shareApiBase;

  final http.Client _http;
  final Uri _base;

  static const _timeout = Duration(seconds: 15);

  Uri _item(String id) => _base.replace(pathSegments: [..._base.pathSegments, id]);

  Future<ShareResult<SentLink>> upload(SharePayload payload) => _guard(() async {
        final res = await _http
            .post(_base, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload.toJson()))
            .timeout(_timeout);
        switch (res.statusCode) {
          case 201:
            final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, Object?>;
            return ShareOk(SentLink(
              id: json['id']! as String,
              url: json['url']! as String,
              deleteToken: json['deleteToken']! as String,
              title: payload.title,
              expiresAt: DateTime.parse(json['expiresAt']! as String),
            ));
          case 413:
            return const ShareTooLarge();
          case 429:
            return const ShareRateLimited();
          default:
            return const ShareFailed();
        }
      });

  Future<ShareResult<SharePayload>> fetch(String id) => _guard(() async {
        final res = await _http.get(_item(id)).timeout(_timeout);
        if (res.statusCode == 404) return const ShareMissing();
        if (res.statusCode != 200) return const ShareFailed();
        return ShareOk(SharePayload.fromJson(jsonDecode(utf8.decode(res.bodyBytes))));
      });

  Future<ShareResult<void>> delete(SentLink link) => _guard(() async {
        final res = await _http
            .delete(_item(link.id), headers: {'Authorization': 'Bearer ${link.deleteToken}'})
            .timeout(_timeout);
        return switch (res.statusCode) {
          204 => const ShareOk<void>(null),
          404 => const ShareMissing<void>(),
          _ => const ShareFailed<void>(),
        };
      });

  /// 연결 끊김, 시간 초과, 망가진 응답은 모두 실패로 본다
  Future<ShareResult<T>> _guard<T>(Future<ShareResult<T>> Function() run) async {
    try {
      return await run();
    } catch (_) {
      return ShareFailed<T>();
    }
  }
}
