import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../share/sent_link.dart';
import '../../share/share_client.dart';
import '../common/adaptive.dart';
import '../design/design.dart';
import '../common/korean_text.dart';

/// 설정 → 보낸 링크. 7일 동안 링크를 다시 복사하거나 먼저 지운다.
class SentLinksScreen extends StatefulWidget {
  const SentLinksScreen({super.key});

  @override
  State<SentLinksScreen> createState() => _SentLinksScreenState();
}

class _SentLinksScreenState extends State<SentLinksScreen> {
  final _deleting = <String>{};

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _copy(SentLink link) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (mounted) _snack('링크를 복사했어요');
  }

  Future<void> _delete(SentLink link) async {
    final ok = await showConfirmDialog(
      context,
      title: '이 링크를 지울까요?',
      message: '받은 사람도 더 이상 열 수 없어요. 이미 추가한 대본은 받은 사람 기기에 남아요.',
      confirmLabel: '지우기',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final services = AppScope.of(context);
    setState(() => _deleting.add(link.id));
    final result = await services.shareClient.delete(link);
    if (result is ShareOk || result is ShareMissing) {
      await services.shareHistory.removeSent(link.id);
      if (mounted) _snack('링크를 지웠어요');
    } else if (mounted) {
      _snack('지우지 못했어요. 인터넷 연결을 확인해 주세요');
    }
    if (mounted) setState(() => _deleting.remove(link.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final links = AppScope.of(context).shareHistory.sent;
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('보낸 링크')),
      body: links.isEmpty
          ? Center(
              child: Text(
                keepWords('7일 안에 보낸 링크가 없어요'),
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 8, 20, 40)),
              itemCount: links.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final link = links[i];
                return Card(
                  child: ListTile(
                    title: Text(link.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${daysLeft(link.expiresAt, now)}일 뒤 사라져요'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(tooltip: '링크 복사', icon: const Icon(Icons.copy_rounded), onPressed: () => _copy(link)),
                        IconButton(
                          tooltip: '지우기',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: _deleting.contains(link.id) ? null : () => _delete(link),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
