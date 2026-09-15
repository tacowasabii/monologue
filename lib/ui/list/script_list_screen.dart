import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/script_repository.dart';
import '../../domain/script_draft.dart';
import '../../domain/script_filter.dart';
import '../../settings/home_view_settings.dart';
import '../common/adaptive.dart';
import '../common/korean_text.dart';
import '../common/section_header.dart';
import '../design/design.dart';
import '../edit/add_script.dart';
import '../settings/settings_screen.dart';
import '../theme.dart';
import '../view/script_view_screen.dart';
import 'filter_bar.dart';

/// 대본 목록. [collection]이 있으면 그 모음의 대본만, [favorites]면 즐겨찾기한 대본만, 둘 다 없으면 전체를 보여 준다.
/// 대본을 길게 누르면 편집 모드가 되어 여러 편을 골라 지우고, 모음 안에서는 모음에서 빼거나 손잡이로 순서를 바꾼다.
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

  /// 연 대본. 넓은 창에서는 목록 옆 칸에 보여 주고, 좁은 창에서는 목록 위에 대본 화면을 띄운다.
  /// 폴드를 접거나 펴서 창 크기가 바뀌어도 보던 대본을 이어서 보여 주려고 기억해 둔다.
  int? _openId;

  /// 좁은 창에서 대본 화면을 띄워 두었거나 띄우려는 중이면 true
  bool _routeOpen = false;

  /// 편집 모드에서 고른 대본. null이면 편집 모드가 아니다.
  Set<int>? _selected;

  /// 마지막으로 그린 목록. 모두 선택과, 검색으로 가려진 대본을 지우지 않는 데 쓴다.
  List<ScriptSummary> _shown = const [];

  bool get _inCollection => widget.collection != null;

  bool get _editing => _selected != null;

  /// 고른 대본 중 지금 목록에 보이는 것만
  List<int> get _selectedShown => [
        for (final s in _shown)
          if (_selected?.contains(s.script.id) ?? false) s.script.id,
      ];

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

  /// 목록이 새로 오면 기억한다. 편집 중이면 위 막대의 고른 수가 맞도록 한 번 더 그린다.
  void _remember(List<ScriptSummary> items) {
    if (identical(items, _shown)) return;
    _shown = items;
    if (_editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _startEditing(int id) => setState(() => _selected = {id});

  void _stopEditing() => setState(() => _selected = null);

  void _toggle(int id) => setState(() {
        if (!_selected!.remove(id)) _selected!.add(id);
      });

  void _toggleAll() => setState(() {
        final ids = {for (final s in _shown) s.script.id};
        _selected = _selected!.containsAll(ids) ? {} : ids;
      });

  /// 고른 대본을 편집 모드에서 내보낸다. 옆 칸에 열어 둔 대본이면 옆 칸도 비운다.
  List<int> _takeSelection() {
    final ids = _selectedShown;
    setState(() {
      if (ids.contains(_openId)) _openId = null;
      _selected = null;
    });
    return ids;
  }

  Future<void> _deleteSelected() async {
    final count = _selectedShown.length;
    final ok = await showConfirmDialog(
      context,
      title: '대본 $count편을 삭제할까요?',
      message: '원본 사진과 연습 기록도 함께 지워져요.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final repo = AppScope.of(context).repo;
    final messenger = ScaffoldMessenger.of(context);
    final ids = _takeSelection();
    await repo.deleteAll(ids);
    messenger.showSnackBar(SnackBar(content: Text('대본 ${ids.length}편을 삭제했어요')));
  }

  /// 모음에서만 뺀다. 대본은 남아서 되돌리기 쉬우므로 묻지 않는다.
  Future<void> _removeSelected() async {
    final repo = AppScope.of(context).repo;
    final messenger = ScaffoldMessenger.of(context);
    final ids = _takeSelection();
    await repo.removeFromCollection(widget.collection!.id, ids);
    messenger.showSnackBar(SnackBar(content: Text('모음에서 ${ids.length}편을 뺐어요. 대본은 전체에 남아 있어요')));
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

  void _open(int id) {
    if (isWideWindow(context)) {
      setState(() => _openId = id);
    } else {
      _pushScript(id);
    }
  }

  Future<void> _pushScript(int id) async {
    _openId = id;
    _routeOpen = true;
    final movedToPane = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ScriptViewScreen(scriptId: id, popWhenWide: true)),
    );
    _routeOpen = false;
    if (!mounted) return;
    // 창이 넓어져서 대본 화면이 스스로 닫혔으면 옆 칸에서 이어 보여 주고, 사용자가 닫았으면 선택을 푼다
    setState(() {
      if (movedToPane != true) _openId = null;
    });
  }

  /// 넓은 창에서 옆 칸에 대본을 보다가 창이 좁아지면(폴드를 접으면) 그 대본 화면을 띄워 이어 보게 한다.
  /// 다른 화면에 가려졌거나 보이지 않는 탭에 있으면, 다시 보일 때 띄운다.
  void _continueInRoute() {
    if (_routeOpen || _openId == null || isWideWindow(context)) return;
    if (!(ModalRoute.isCurrentOf(context) ?? true) || !Visibility.of(context)) return;
    _routeOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeOpen = false;
      final id = _openId;
      if (mounted && id != null) _pushScript(id);
    });
  }

  String get _title {
    if (widget.collection case final c?) return c.name;
    return widget.favorites ? '즐겨찾기' : '전체';
  }

  PreferredSizeWidget _appBar(ThemeData theme) {
    if (_editing) {
      final count = _selectedShown.length;
      final all = _shown.isNotEmpty && count == _shown.length;
      return AppBar(
        toolbarHeight: widget.home ? 72 : null,
        leading: IconButton(tooltip: '편집 끝내기', icon: const Icon(Icons.close_rounded), onPressed: _stopEditing),
        title: Text(count == 0 ? '대본 고르기' : '$count편 선택'),
        actions: [
          TextButton(onPressed: _shown.isEmpty ? null : _toggleAll, child: Text(all ? '선택 해제' : '모두 선택')),
          const SizedBox(width: AppSpace.sm),
        ],
      );
    }
    if (widget.home) {
      return AppBar(
        toolbarHeight: 72,
        titleSpacing: AppSpace.page,
        title: Text('모노로그', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: AppSpace.sm),
        ],
      );
    }
    return AppBar(title: Text(_title));
  }

  @override
  Widget build(BuildContext context) {
    _continueInRoute();
    final theme = Theme.of(context);
    final wide = isWideWindow(context);
    final selectedCount = _selectedShown.length;
    final list = Scaffold(
      appBar: _appBar(theme),
      body: StreamBuilder<List<String>>(
        stream: _tags,
        builder: (context, tagSnap) {
          final tags = tagSnap.data ?? const <String>[];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xs),
                child: SearchBar(
                  hintText: '작품, 설명, 본문 검색',
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
                    _remember(items);
                    if (items.isEmpty) {
                      return _EmptyMessage(
                        filtered: _filter.isActive,
                        inCollection: _inCollection,
                        favorites: widget.favorites,
                      );
                    }
                    const padding = EdgeInsets.fromLTRB(AppSpace.page, 14, AppSpace.page, AppSize.fabClearance);
                    Widget card(ScriptSummary s, {int? dragIndex}) {
                      final id = s.script.id;
                      return Padding(
                        key: ValueKey(id),
                        padding: const EdgeInsets.only(bottom: AppSpace.md),
                        child: _ScriptCard(
                          summary: s,
                          selected: !_editing && wide && id == _openId,
                          checked: _selected?.contains(id),
                          dragIndex: dragIndex,
                          onTap: _editing ? () => _toggle(id) : () => _open(id),
                          onLongPress: _editing ? null : () => _startEditing(id),
                        ),
                      );
                    }

                    // 걸러 보는 중에는 일부만 보여서 순서를 바꾸지 않는다
                    if (_inCollection && !_filter.isActive && items.length > 1) {
                      return ReorderableListView.builder(
                        padding: padding,
                        // 길게 누르기는 편집 모드에 쓰고, 순서는 편집 모드의 손잡이로만 바꾼다
                        buildDefaultDragHandles: false,
                        header: _CountHeader(
                          _editing
                              ? '대본 ${items.length}편 · ≡를 끌어 순서를 바꿔요'
                              : '대본 ${items.length}편 · 길게 누르면 고르거나 순서를 바꿔요',
                        ),
                        itemCount: items.length,
                        onReorderItem: (from, to) => _reorder(items, from, to),
                        proxyDecorator: (child, index, animation) => AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) => Transform.scale(scale: 1 + 0.03 * animation.value, child: child),
                          child: child,
                        ),
                        itemBuilder: (context, i) => card(items[i], dragIndex: _editing ? i : null),
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
      // 즐겨찾기는 별을 눌러 모이는 곳이라 여기서 새 대본을 만들지 않는다. 편집 중에는 아래 막대가 대신한다
      floatingActionButton: widget.favorites || _editing
          ? null
          : FloatingActionButton.extended(
              onPressed: () => addScript(context, collectionId: widget.collection?.id),
              icon: const Icon(Icons.add_rounded),
              label: const Text('대본 추가'),
            ),
      bottomNavigationBar: _editing
          ? AppActionBar(
              actions: [
                if (_inCollection)
                  AppAction(
                    '모음에서 빼기',
                    kind: AppActionKind.secondary,
                    icon: Icons.folder_off_outlined,
                    onPressed: selectedCount == 0 ? null : _removeSelected,
                  ),
                AppAction(
                  '삭제',
                  kind: AppActionKind.destructive,
                  icon: Icons.delete_outline_rounded,
                  onPressed: selectedCount == 0 ? null : _deleteSelected,
                ),
              ],
            )
          : null,
    );
    final openId = _openId;
    // 좁은 창에서도 같은 틀을 써서, 창 크기가 바뀌어도 목록(검색어·스크롤 위치)을 새로 만들지 않는다.
    // 바깥 Scaffold는 두 칸이 SnackBar를 한 번만 보여 주게 한다
    return PopScope(
      // 편집 중에 뒤로 가면 화면을 닫지 않고 편집 모드만 끝낸다
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _editing) _stopEditing();
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: wide ? (constraints.maxWidth * 0.4).clamp(280.0, 400.0) : constraints.maxWidth,
                child: list,
              ),
              if (wide) ...[
                const VerticalDivider(width: 1),
                Expanded(
                  child: openId == null
                      ? const _NothingOpen()
                      : ScriptViewScreen(
                          key: ValueKey(openId),
                          scriptId: openId,
                          onDeleted: () => setState(() => _openId = null),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 넓은 창에서 아직 대본을 열지 않았을 때의 옆 칸
class _NothingOpen extends StatelessWidget {
  const _NothingOpen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 40, color: scheme.outline),
          const SizedBox(height: 14),
          Text('대본을 고르면 여기에 보여요', style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
        ],
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
      // 검색창을 가리지 않게 버튼 아래로 띄운다
      position: PopupMenuPosition.under,
      offset: const Offset(0, AppSpace.sm),
      constraints: const BoxConstraints(minWidth: 200),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final s in ScriptSort.values) appMenuItem(context, value: s, label: s.label, selected: s == sort),
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
        padding: const EdgeInsets.fromLTRB(40, AppSpace.xl, 40, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, color: scheme.primary, size: 34),
            ),
            const SizedBox(height: AppSpace.xl),
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
  const _ScriptCard({
    required this.summary,
    required this.selected,
    required this.checked,
    required this.dragIndex,
    required this.onTap,
    required this.onLongPress,
  });

  final ScriptSummary summary;

  /// 넓은 창에서 옆 칸에 열어 둔 대본이면 true
  final bool selected;

  /// 편집 모드에서 골랐으면 true, 고르지 않았으면 false. 편집 모드가 아니면 null.
  final bool? checked;

  /// 편집 모드의 모음 안이면 순서 손잡이가 옮길 자리
  final int? dragIndex;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

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
    final highlighted = selected || checked == true;
    final trailing = switch (checked) {
      null => IconButton(
          key: const ValueKey('favorite'),
          visualDensity: VisualDensity.compact,
          tooltip: s.favorite ? '즐겨찾기 해제' : '즐겨찾기',
          icon: Icon(
            s.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
            color: s.favorite ? favoriteColor(scheme) : scheme.outline,
          ),
          onPressed: () => repo.setFavorite(s.id, !s.favorite),
        ),
      final isChecked => Row(
          key: const ValueKey('select'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dragIndex case final index?)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  child: Icon(Icons.drag_handle_rounded, color: scheme.onSurfaceVariant, semanticLabel: '끌어서 순서 바꾸기'),
                ),
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: isChecked ? '선택 해제' : '선택',
              icon: Icon(
                isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isChecked ? scheme.primary : scheme.outline,
              ),
              onPressed: onTap,
            ),
          ],
        ),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      color: highlighted ? scheme.primaryContainer.withValues(alpha: 0.45) : null,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 14, 6, 18),
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
                  AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: trailing),
                ],
              ),
              if (excerpt.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AppSpace.md, right: 14),
                  padding: const EdgeInsets.only(left: AppSpace.md),
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
