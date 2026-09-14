import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../share/share_client.dart';
import '../../share/share_payload.dart';

/// 대본 화면 ⋯ 메뉴의 "링크로 공유". [anchor]는 iPad에서 공유 시트를 띄울 자리.
Future<void> shareScriptByLink(BuildContext context, ScriptDetail detail, {Rect? anchor}) async {
  final services = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  void snack(String text) => messenger.showSnackBar(SnackBar(content: Text(text)));

  if (!services.shareHistory.noticeSeen) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('링크로 공유'),
        content: const Text('대본 글이 서버에 7일 동안 저장되고, 링크를 가진 사람은 누구나 볼 수 있어요. 메모, 사진, 연습 기록은 보내지 않아요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('확인')),
        ],
      ),
    );
    if (ok != true) return;
    await services.shareHistory.markNoticeSeen();
  }

  var includeNote = false;
  if (detail.script.note != null) {
    if (!context.mounted) return;
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트도 함께 보낼까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('노트 빼고 보내기')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('함께 보내기')),
        ],
      ),
    );
    if (choice == null) return;
    includeNote = choice;
  }

  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
  );
  final result = await services.shareClient.upload(SharePayload.fromDetail(detail, includeNote: includeNote));
  rootNavigator.pop();

  switch (result) {
    case ShareOk(:final value):
      await services.shareHistory.addSent(value);
      try {
        await SharePlus.instance.share(ShareParams(
          text: '「${value.title}」 대본을 보냈어요\n${value.url}',
          sharePositionOrigin: anchor,
        ));
      } catch (_) {
        snack('공유 화면을 열지 못했어요');
      }
    case ShareTooLarge():
      snack('대본이 너무 길어서 링크로 보낼 수 없어요');
    case ShareRateLimited():
      snack('잠시 뒤 다시 시도해 주세요');
    case ShareMissing() || ShareFailed():
      snack('지금 링크를 만들 수 없어요. 인터넷 연결을 확인하고 다시 시도해 주세요');
  }
}
