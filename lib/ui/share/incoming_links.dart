import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../share/share_link.dart';
import 'received_script_screen.dart';

/// 앱을 여는 공유 링크를 받아 받은 대본 화면을 연다.
class IncomingLinks extends StatefulWidget {
  const IncomingLinks({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<IncomingLinks> createState() => _IncomingLinksState();
}

class _IncomingLinksState extends State<IncomingLinks> {
  StreamSubscription<Uri>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription ??= AppScope.of(context).links.links.listen(_open);
  }

  void _open(Uri uri) {
    if (!mounted) return;
    final id = shareIdFromUri(uri);
    if (id == null) return;
    final navigator = widget.navigatorKey.currentState;
    // 링크로 앱을 처음 켜면 첫 화면을 그리기 전에 링크가 올 수 있다
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(uri));
      return;
    }
    navigator.push(MaterialPageRoute<void>(builder: (_) => ReceivedScriptScreen(shareId: id)));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
