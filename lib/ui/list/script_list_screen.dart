import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/script_repository.dart';
import '../../domain/script_draft.dart';
import '../../domain/script_filter.dart';
import '../common/korean_text.dart';
import '../edit/add_script.dart';
import '../settings/settings_screen.dart';
import '../theme.dart';
import '../view/script_view_screen.dart';
import 'filter_bar.dart';

/// 대본 목록. [collection]이 있으면 그 모음의 대본만, 없으면 전체를 보여 준다.
class ScriptListScreen extends StatefulWidget {
  const ScriptListScreen({super.key, this.collection, this.home = false});

  final Collection? collection;

  /// 앱 첫 화면의 대본 탭으로 쓸 때. 앱 이름을 크게 보여 주고 설정 버튼을 둔다.
  final bool home;

  @override
  State<ScriptListScreen> createState() => _ScriptListScreenState();
}

class _ScriptListScreenState extends State<ScriptListScreen> {
  late ScriptFilter _filter = ScriptFilter(collectionId: widget.collection?.id);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: widget.home
          ? AppBar(
              toolbarHeight: 72,
              titleSpacing: 20,
              title: Text('모노로그', style: theme.textTheme.headlineMedium),
              actions: [
                IconButton(
                  tooltip: '설정',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
                ),
                const SizedBox(width: 8),
              ],
            )
          : AppBar(title: Text(widget.collection?.name ?? '전체')),
      body: StreamBuilder<List<String>>(
        stream: _tags,
        builder: (context, tagSnap) {
          final tags = tagSnap.data ?? const <String>[];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: SearchBar(
                  hintText: '작품, 메모, 본문 검색',
                  leading: Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
                  trailing: [
                    FavoritesButton(filter: _filter, onChanged: _setFilter),
                    FilterButton(filter: _filter, tags: tags, onChanged: _setFilter),
                  ],
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
                    if (items.isEmpty) {
                      return _EmptyMessage(filtered: _filter.isActive, inCollection: widget.collection != null);
                    }
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
        onPressed: () => addScript(context, collectionId: widget.collection?.id),
        icon: const Icon(Icons.add_rounded),
        label: const Text('대본 추가'),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.filtered, required this.inCollection});

  final bool filtered;
  final bool inCollection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, title, message) = filtered
        ? (Icons.search_off_rounded, '조건에 맞는 대본이 없어요', '검색어나 필터를 바꿔 보세요')
        : inCollection
            ? (
                Icons.folder_open_outlined,
                '이 모음에 아직 대본이 없어요',
                '여기서 대본을 추가하면 이 모음에 바로 들어가요.\n이미 있는 대본은 편집 화면에서 모음을 골라 넣어요',
              )
            : (Icons.format_quote_rounded, '아직 대본이 없어요', '대본 사진을 올리면\n글자를 읽어 노트로 정리해 드려요');
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
              child: Icon(icon, color: scheme.primary, size: 34),
            ),
            const SizedBox(height: 24),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              keepWords(message),
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

  /// 작품명이 없으면 본문 첫 줄이 제목 자리로 올라가므로, 미리보기는 그다음 줄부터 보여 준다.
  static String _excerpt(String body, {required bool skipFirstLine}) {
    final lines = body.trim().split('\n');
    if (skipFirstLine) lines.removeAt(0);
    return lines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = summary.script;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final repo = AppScope.of(context).repo;
    final work = s.work;
    final heading = work ?? firstLineOf(s.body);
    final excerpt = _excerpt(s.body, skipFirstLine: work == null);
    // 같은 작품의 독백이 여러 개여도 구분되도록 메모 첫 줄을 제목 아래에 보여 준다
    final memoLine = firstLineOf(s.memo ?? '');
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
                            heading,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, height: 1.35),
                          ),
                          if (memoLine.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                memoLine,
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
                    keepWords(excerpt),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: serifFamily, fontSize: 14, height: 1.6, color: scheme.onSurfaceVariant),
                  ),
                ),
              if (summary.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14, right: 14),
                  child: Text(
                    summary.tags.map((t) => '#$t').join('  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
