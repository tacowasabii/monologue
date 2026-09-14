import 'package:app_links/app_links.dart';

/// 앱을 여는 링크. 테스트에서는 가짜로 바꾼다.
abstract class LinkSource {
  /// 앱이 꺼진 상태에서 링크로 켰을 때의 링크도 처음에 한 번 흘려보낸다.
  Stream<Uri> get links;
}

class PlatformLinkSource implements LinkSource {
  final _appLinks = AppLinks();

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;
}
