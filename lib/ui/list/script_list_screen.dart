import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/script_repository.dart';
import '../../domain/script_draft.dart';
import '../../domain/script_filter.dart';
import '../../settings/home_view_settings.dart';
import '../common/korean_text.dart';
import '../common/section_header.dart';
import '../edit/add_script.dart';
import '../settings/settings_screen.dart';
import '../theme.dart';
import '../view/script_view_screen.dart';
import 'filter_bar.dart';

/// 대본 목록. [collection]이 있으면 그 모음의 대본만, [favorites]면 즐겨찾기한 대본만, 둘 다 없으면 전체를 보여 준다.
class ScriptListScreen extends StatefulWidget {
  const ScriptListScreen({super.key, this.collection, this.favorites = false, this.home = false});

  final Collection? collection;

  /// 모음 탭의 즐겨찾기 모음
  final bool favorites;

  /// 앱 첫 화면의 대본 탭으로 쓸 때. 앱 이름을 크게 보여 주고 설정 버튼을 둔다.
  final bool home;

  @override
  State<ScriptListScreen> createState() => _ScriptListScreenState();
}

class _ScriptListScreenState extends State<ScriptListScreen> {
  late ScriptFilter _filter = ScriptFilter(collectionId: widget.collection?.id, favoritesOnly: widget.favorites);
  Stream<List<ScriptSummary>>? _scripts;
  Stream<List<String>>? _tags;
  HomeViewSettings? _homeView;

  /// 끌어서 옮긴 순서. 저장한 순서가 목록으로 돌아올 때까지 이 순서로 보여 줘서 카드가 제자리로 튀지 않게 한다.
  List<ScriptSummary>? _moved;

  bool get _inCollection => widget.collection != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppScope.of(context);
    if (_homeView == null) {
      _homeView = services.homeView..addListener(_onSortChanged);
      _filter = _filter.copyWith(sort: services.homeView.sort);
    }
    _scripts ??= services.repo.watchScripts(_filter);
    _tags ??= services.repo.watchAllTags();
  }

  @override
  void dispose() {
    _homeView?.removeListener(_onSortChanged);
    super.dispose();
  }

  // 대본 탭과 전체·즐겨찾기 화면이 같은 정렬 설정을 쓴다
  void _onSortChanged() {
    final sort = _homeView!.sort;
    if (sort != _filter.sort) _setFilter(_filter.copyWith(sort: sort));
  }

  void _setFilter(ScriptFilter filter) {
    setState(() {
      _filter = filter;
      _scripts = AppScope.of(context).repo.watchScripts(filter);
    });
  }

  /// [to]는 [from]의 대본을 뺀 목록에서의 자리다.
  Future<void> _reorder(List<ScriptSummary> items, int from, int to) async {
    final repo = AppScope.of(context).repo;
    final moved = [...items];
    moved.insert(to, moved.removeAt(from));
    setState(() => _moved = moved);
    await repo.reorderCollection(widget.collection!.id, [for (final s in moved) s.script.id]);
  }

  /// 옮긴 순서를 저장하는 동안에는 옮긴 순서를, 저장한 순서가 돌아오거나 목록이 달라지면 받은 목록을 쓴다.
  List<ScriptSummary> _withMoved(List<ScriptSummary> items) {
    final moved = _moved;
    if (moved == null) return items;
    final movedIds = [for (final s in moved) s.script.id];
    final itemIds = [for (final s in items) s.script.id];
    var sameOrder = movedIds.length == itemIds.length;
    for (var i = 0; sameOrder && i < movedIds.length; i++) {
      sameOrder = movedIds[i] == itemIds[i];
    }
    final sameScripts = movedIds.length == itemIds.length && movedIds.toSet().containsAll(itemIds);
    if (sameOrder || !sameScripts) {
      _moved = null;
      return items;
    }
    return moved;
  }

  String get _title {
    if (widget.collection case final c?) return c.name;
    return widget.favorites ? '즐겨찾기' : '전체';
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
          : AppBar(title: Text(_title)),
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
                    // 모음 안에서는 직접 정한 순서로 보여 주므로 정렬 기준을 고르지 않는다
                    if (!_inCollection) _SortButton(sort: _filter.sort, onChanged: (s) => _homeView!.setSort(s)),
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
                    final items = _withMoved(snap.data!);
                    if (items.isEmpty) {
                      return _EmptyMessage(
                        filtered: _filter.isActive,
                        inCollection: _inCollection,
                        favorites: widget.favorites,
                      );
                    }
                    const padding = EdgeInsets.fromLTRB(20, 14, 20, 112);
                    Widget card(ScriptSummary s) => Padding(
                          key: ValueKey(s.script.id),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ScriptCard(summary: s),
                        );

                    // 걸러 보는 중에는 일부만 보여서 순서를 바꾸지 않는다
                    if (_inCollection && !_filter.isActive && items.length > 1) {
                      return ReorderableListView.builder(
                        padding: padding,
                        header: _CountHeader('대본 ${items.length}편 · 길게 눌러 끌면 순서를 바꿔요'),
                        itemCount: items.length,
                        onReorderItem: (from, to) => _reorder(items, from, to),
                        proxyDecorator: (child, index, animation) => AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) => Transform.scale(scale: 1 + 0.03 * animation.value, child: child),
                          child: child,
                        ),
                        itemBuilder: (context, i) => card(items[i]),
                      );
                    }

                    // 전체 목록에서는 즐겨찾기한 대본을 맨 위 구역에 모은다. 같은 대본을 두 번 보여 주지 않는다
                    final sectioned = !_inCollection && !widget.favorites && !_filter.isActive;
                    final favorites = sectioned ? items.where((s) => s.script.favorite).toList() : const <ScriptSummary>[];
                    final others = items.where((s) => !s.script.favorite).toList();
                    final rows = <Widget Function()>[
                      if (favorites.isEmpty) ...[
                        () => _CountHeader(_filter.isActive ? '찾은 대본 ${items.length}편' : '대본 ${items.length}편'),
                        for (final s in items) () => card(s),
                      ] else ...[
                        () => SectionHeader('즐겨찾기 ${favorites.length}편', first: true),
                        for (final s in favorites) () => card(s),
                        if (others.isNotEmpty) ...[
                          () => SectionHeader('대본 ${others.length}편'),
                          for (final s in others) () => card(s),
                        ],
                      ],
                    ];
                    return ListView.builder(
                      padding: padding,
                      itemCount: rows.length,
                      itemBuilder: (context, i) => rows[i](),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      // 즐겨찾기는 별을 눌러 모이는 곳이라 여기서 새 대본을 만들지 않는다
      floatingActionButton: widget.favorites
          ? null
          : FloatingActionButton.extended(
              onPressed: () => addScript(context, collectionId: widget.collection?.id),
              icon: const Icon(Icons.add_rounded),
              label: const Text('대본 추가'),
            ),
    );
  }
}

/// 목록 위의 작은 개수 표시
class _CountHeader extends StatelessWidget {
  const _CountHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// 검색창 안의 정렬 버튼. 고른 기준은 대본 탭·전체·즐겨찾기가 함께 쓰고 앱을 다시 켜도 기억한다.
class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onChanged});

  final ScriptSort sort;
  final ValueChanged<ScriptSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ScriptSort>(
      tooltip: '정렬 · ${sort.label}',
      icon: Icon(Icons.swap_vert_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
      initialValue: sort,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final s in ScriptSort.values) CheckedPopupMenuItem(value: s, checked: s == sort, child: Text(s.label)),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.filtered, required this.inCollection, required this.favorites});

  final bool filtered;
  final bool inCollection;
  final bool favorites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, title, message) = filtered
        ? (Icons.search_off_rounded, '조건에 맞는 대본이 없어요', '검색어나 필터를 바꿔 보세요')
        : favorites
            ? (Icons.star_outline_rounded, '아직 즐겨찾기한 대본이 없어요', '대본 목록이나 대본 화면에서 ☆를 누르면\n여기에 모여요')
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
