import 'dart:math' as math;

/// 이 기기에서 보낸 공유 링크. [deleteToken]이 있어야 서버에서 지울 수 있다.
class SentLink {
  const SentLink({
    required this.id,
    required this.url,
    required this.deleteToken,
    required this.title,
    required this.expiresAt,
  });

  final String id;
  final String url;
  final String deleteToken;
  final String title;
  final DateTime expiresAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'url': url,
        'deleteToken': deleteToken,
        'title': title,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
      };

  static SentLink? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    final url = json['url'];
    final token = json['deleteToken'];
    final title = json['title'];
    final expires = json['expiresAt'];
    if (id is! String || url is! String || token is! String || title is! String || expires is! String) return null;
    final expiresAt = DateTime.tryParse(expires);
    if (expiresAt == null) return null;
    return SentLink(id: id, url: url, deleteToken: token, title: title, expiresAt: expiresAt);
  }
}

/// 링크가 사라질 때까지 남은 날짜. 하루가 안 남아도 1일로, 링크 수명(7일)보다 크게 보이지 않게 한다.
int daysLeft(DateTime expiresAt, DateTime now) {
  final days = (expiresAt.difference(now).inMinutes / (24 * 60)).ceil();
  return math.max(1, math.min(7, days));
}
