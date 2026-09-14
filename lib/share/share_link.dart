/// 공유 링크와 공유 API가 있는 사이트. 바꾸면 앱 링크 설정(iOS 연결 도메인, Android 인텐트 필터)도 함께 바꾼다.
const shareHost = 'tacowasabii.vercel.app';

final shareApiBase = Uri.https(shareHost, '/api/monologue/shares');

final _shareId = RegExp(r'^[A-Za-z0-9_-]{22}$');

/// [uri]가 대본 공유 링크면 ID를 준다.
/// 메신저에서 누르는 `https://tacowasabii.vercel.app/monologue/s/<ID>`와
/// 웹 보기의 "앱에서 열기"가 여는 `monologue://s/<ID>`를 받는다.
String? shareIdFromUri(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  String? candidate;
  if (uri.scheme == 'https' && uri.host == shareHost && segments.length == 3 && segments[0] == 'monologue' && segments[1] == 's') {
    candidate = segments[2];
  } else if (uri.scheme == 'monologue' && uri.host == 's' && segments.length == 1) {
    candidate = segments[0];
  }
  return candidate != null && _shareId.hasMatch(candidate) ? candidate : null;
}
