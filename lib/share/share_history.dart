import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sent_link.dart';

/// 이 기기에서 보낸 링크, 받은 링크로 만든 대본, 첫 공유 안내 확인 여부를 기억한다. 백업 파일에는 넣지 않는다.
class ShareHistory {
  ShareHistory._(this._prefs, this._sent, this._received, this._noticeSeen, this._now);

  static const _sentKey = 'share.sent';
  static const _receivedKey = 'share.received';
  static const _noticeKey = 'share.noticeSeen';

  final SharedPreferencesAsync _prefs;
  final List<SentLink> _sent;
  final Map<String, int> _received;
  bool _noticeSeen;
  final DateTime Function() _now;

  static Future<ShareHistory> load({DateTime Function() now = DateTime.now}) async {
    final prefs = SharedPreferencesAsync();

    Object? decode(String? raw) {
      if (raw == null) return null;
      try {
        return jsonDecode(raw);
      } on FormatException {
        return null;
      }
    }

    final sentJson = decode(await prefs.getString(_sentKey));
    final sent = [
      if (sentJson is List)
        for (final item in sentJson) ?SentLink.tryFromJson(item),
    ];
    final receivedJson = decode(await prefs.getString(_receivedKey));
    final received = <String, int>{
      if (receivedJson is Map)
        for (final entry in receivedJson.entries)
          if (entry.key is String && entry.value is int) entry.key as String: entry.value as int,
    };
    return ShareHistory._(prefs, sent, received, (await prefs.getBool(_noticeKey)) ?? false, now);
  }

  /// 아직 만료되지 않은 보낸 링크, 최근 것부터
  List<SentLink> get sent {
    final now = _now();
    return [
      for (final link in _sent.reversed)
        if (link.expiresAt.isAfter(now)) link,
    ];
  }

  Future<void> addSent(SentLink link) async {
    final now = _now();
    _sent
      ..removeWhere((l) => !l.expiresAt.isAfter(now))
      ..add(link);
    await _saveSent();
  }

  Future<void> removeSent(String id) async {
    _sent.removeWhere((l) => l.id == id);
    await _saveSent();
  }

  int? receivedScriptId(String shareId) => _received[shareId];

  Future<void> markReceived(String shareId, int scriptId) async {
    _received[shareId] = scriptId;
    await _prefs.setString(_receivedKey, jsonEncode(_received));
  }

  bool get noticeSeen => _noticeSeen;

  Future<void> markNoticeSeen() async {
    _noticeSeen = true;
    await _prefs.setBool(_noticeKey, true);
  }

  Future<void> _saveSent() => _prefs.setString(_sentKey, jsonEncode([for (final l in _sent) l.toJson()]));
}
