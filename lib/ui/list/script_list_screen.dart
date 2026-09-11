import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../domain/enums.dart';
import '../../domain/script_filter.dart';
import '../capture/capture_flow.dart';
import '../edit/script_edit_screen.dart';
import '../settings/settings_screen.dart';
import '../view/script_view_screen.dart';
import 'filter_bar.dart';

class ScriptListScreen extends StatefulWidget {
  const ScriptListScreen({super.key});

  @override
  State<ScriptListScreen> createState() => _ScriptListScreenState();
}

class _ScriptListScreenState extends State<ScriptListScreen> {
  ScriptFilter _filter = const ScriptFilter();
  Stream<List<ScriptSummary>>? _scripts;
  Stream<List<String>>? _tags;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = AppScope.of(context).repo;
    _scripts ??= repo.watchScripts(_filter);
    _tags ??= repo.watchAllTags();
  }

  void _setFilter(ScriptFilter filter) {
    setState(() {
      _filter = filter;
      _scripts = AppScope.of(context).repo.watchScripts(filter);
    });
  }

  Future<void> _add() async {
    final result = await runCapture(context);
    if (result == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<int>(
      builder: (_) => ScriptEditScreen(
        initialBody: result.text,
        newImagePaths: result.imagePaths,
        failedImages: result.failedCount,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모노로그'),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              hintText: '제목, 작품, 인물, 본문 검색',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (q) => _setFilter(_filter.copyWith(query: q)),
            ),
          ),
          StreamBuilder<List<String>>(
            stream: _tags,
            builder: (context, snap) => FilterBar(filter: _filter, tags: snap.data ?? const [], onChanged: _setFilter),
          ),
          Expanded(
            child: StreamBuilder<List<ScriptSummary>>(
              stream: _scripts,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final items = snap.data!;
                if (items.isEmpty) return _EmptyMessage(filtered: _filter.isActive);
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, i) => _ScriptTile(summary: items[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('대본 추가'),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          filtered ? '조건에 맞는 대본이 없어요' : '아직 대본이 없어요\n사진을 올려 첫 대본을 추가해 보세요',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.6),
        ),
      ),
    );
  }
}

class _ScriptTile extends StatelessWidget {
  const _ScriptTile({required this.summary});

  final ScriptSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary.script;
    final repo = AppScope.of(context).repo;
    final meta = [s.work, s.character].whereType<String>().join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
      title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta.isNotEmpty) Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Pill(s.status.label, emphasized: s.status == PracticeStatus.memorized),
              for (final t in summary.tags) _Pill('#$t'),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        tooltip: s.favorite ? '즐겨찾기 해제' : '즐겨찾기',
        icon: Icon(
          s.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: s.favorite ? Colors.amber.shade600 : null,
        ),
        onPressed: () => repo.setFavorite(s.id, !s.favorite),
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ScriptViewScreen(scriptId: s.id))),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.emphasized = false});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: emphasized ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: emphasized ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
