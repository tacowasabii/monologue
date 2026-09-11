import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../domain/script_filter.dart';
import '../capture/capture_flow.dart';
import '../common/status_badge.dart';
import '../edit/script_edit_screen.dart';
import '../settings/settings_screen.dart';
import '../theme.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Text('모노로그', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: _tags,
        builder: (context, tagSnap) {
          final tags = tagSnap.data ?? const <String>[];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: SearchBar(
                  hintText: '제목, 작품, 인물, 본문 검색',
                  leading: Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
                  trailing: [FilterButton(filter: _filter, tags: tags, onChanged: _setFilter)],
                  padding: const WidgetStatePropertyAll(EdgeInsetsDirectional.only(start: 16, end: 4)),
                  elevation: const WidgetStatePropertyAll(0),
                  onChanged: (q) => _setFilter(_filter.copyWith(query: q)),
                ),
              ),
              FilterBar(filter: _filter, tags: tags, onChanged: _setFilter),
              Expanded(
                child: StreamBuilder<List<ScriptSummary>>(
                  stream: _scripts,
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final items = snap.data!;
                    if (items.isEmpty) return _EmptyMessage(filtered: _filter.isActive);
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 112),
                      itemCount: items.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Text(
                              _filter.isActive ? '찾은 대본 ${items.length}편' : '대본 ${items.length}편',
                              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ScriptCard(summary: items[i - 1]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
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
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 24, 40, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(
                filtered ? Icons.search_off_rounded : Icons.format_quote_rounded,
                color: scheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              filtered ? '조건에 맞는 대본이 없어요' : '아직 대본이 없어요',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              filtered ? '검색어나 필터를 바꿔 보세요' : '대본 사진을 올리면\n글자를 읽어 노트로 정리해 드려요',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScriptCard extends StatelessWidget {
  const _ScriptCard({required this.summary});

  final ScriptSummary summary;

  /// 제목이 본문 첫 줄에서 온 경우가 많아서, 첫 줄이 제목과 같으면 빼고 이어지는 대사를 보여준다.
  static String _excerpt(String title, String body) {
    final lines = body.trim().split('\n');
    if (lines.first.trim() == title.trim()) lines.removeAt(0);
    return lines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = summary.script;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final repo = AppScope.of(context).repo;
    final meta = [s.work, s.character].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
    final excerpt = _excerpt(s.title, s.body);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ScriptViewScreen(scriptId: s.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 6, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, height: 1.35),
                          ),
                          if (meta.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: s.favorite ? '즐겨찾기 해제' : '즐겨찾기',
                    icon: Icon(
                      s.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: s.favorite ? favoriteColor(scheme) : scheme.outline,
                    ),
                    onPressed: () => repo.setFavorite(s.id, !s.favorite),
                  ),
                ],
              ),
              if (excerpt.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12, right: 14),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: scheme.primary.withValues(alpha: 0.35), width: 2)),
                  ),
                  child: Text(
                    excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: serifFamily, fontSize: 14, height: 1.6, color: scheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Row(
                  children: [
                    StatusBadge(s.status),
                    if (summary.tags.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          summary.tags.map((t) => '#$t').join('  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
