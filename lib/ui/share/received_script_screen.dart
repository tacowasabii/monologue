import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../domain/enums.dart';
import '../../share/sent_link.dart';
import '../../share/share_client.dart';
import '../../share/share_payload.dart';
import '../common/adaptive.dart';
import '../common/korean_text.dart';
import '../view/script_body.dart';
import '../view/script_view_screen.dart';

typedef _Loaded = ({int? existingScriptId, ShareResult<SharePayload>? result});

/// 받은 공유 링크의 대본을 보여 주고 내 대본으로 추가한다.
class ReceivedScriptScreen extends StatefulWidget {
  const ReceivedScriptScreen({super.key, required this.shareId});

  final String shareId;

  @override
  State<ReceivedScriptScreen> createState() => _ReceivedScriptScreenState();
}

class _ReceivedScriptScreenState extends State<ReceivedScriptScreen> {
  Future<_Loaded>? _loaded;
  bool _adding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loaded ??= _load();
  }

  Future<_Loaded> _load() async {
    final services = AppScope.of(context);
    final existing = services.shareHistory.receivedScriptId(widget.shareId);
    // 이미 추가한 대본이 남아 있으면 서버에 묻지 않는다(지웠으면 다시 추가할 수 있다)
    if (existing != null && await services.repo.watchScript(existing).first != null) {
      return (existingScriptId: existing, result: null);
    }
    return (existingScriptId: null, result: await services.shareClient.fetch(widget.shareId));
  }

  void _openScript(int id) =>
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => ScriptViewScreen(scriptId: id)));

  Future<void> _add(SharePayload payload) async {
    final services = AppScope.of(context);
    setState(() => _adding = true);
    try {
      final id = await services.repo.create(payload.toDraft());
      await services.shareHistory.markReceived(widget.shareId, id);
      if (!mounted) return;
      _openScript(id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _adding = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('추가하지 못했어요. 다시 시도해 주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('받은 대본')),
      body: FutureBuilder<_Loaded>(
        future: _loaded,
        builder: (context, snap) {
          final loaded = snap.data;
          if (loaded == null) return const Center(child: CircularProgressIndicator());
          final existing = loaded.existingScriptId;
          if (existing != null) {
            return _Message(
              icon: Icons.check_circle_outline_rounded,
              text: '이미 추가한 대본이에요',
              actionLabel: '열기',
              onAction: () => _openScript(existing),
            );
          }
          return switch (loaded.result!) {
            ShareOk(:final value) => _Preview(payload: value),
            ShareMissing() => const _Message(icon: Icons.link_off_rounded, text: '7일이 지나 사라졌거나 보낸 사람이 지운 링크예요'),
            _ => _Message(
                icon: Icons.wifi_off_rounded,
                text: '인터넷 연결을 확인해 주세요',
                actionLabel: '다시 시도',
                onAction: () => setState(() {
                  _loaded = _load();
                }),
              ),
          };
        },
      ),
      bottomNavigationBar: FutureBuilder<_Loaded>(
        future: _loaded,
        builder: (context, snap) {
          final result = snap.data?.result;
          if (snap.data?.existingScriptId != null || result is! ShareOk<SharePayload>) return const SizedBox.shrink();
          return SafeArea(
            child: Padding(
              padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 12, 20, 12)),
              child: FilledButton(
                onPressed: _adding ? null : () => _add(result.value),
                child: const Text('내 대본에 추가'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.payload});

  final SharePayload payload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = AppScope.of(context).settings;
    final labels = [
      if (payload.gender != Gender.any) payload.gender.label,
      if (payload.ageRange != AgeRange.any) payload.ageRange.label,
      for (final t in payload.tags) '#$t',
    ];
    final expiresAt = payload.expiresAt;
    final note = payload.note;
    return ListView(
      padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(24, 8, 24, 32)),
      children: [
        Text(keepWords(payload.title), style: theme.textTheme.headlineMedium?.copyWith(height: 1.3)),
        if (labels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final l in labels) Chip(label: Text(l), visualDensity: VisualDensity.compact)],
            ),
          ),
        if (expiresAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${daysLeft(expiresAt, DateTime.now())}일 뒤 링크가 사라져요. 추가한 대본은 계속 남아요.',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('노트', style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                    const SizedBox(height: 6),
                    Text(keepWords(note), style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ScriptBody(
            body: payload.body,
            dialogue: payload.dialogue,
            fontSize: settings.fontSize,
            selectable: false,
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.actionLabel, this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = actionLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(keepWords(text), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            if (label != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
