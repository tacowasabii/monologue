import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/script_repository.dart';
import '../../settings/home_view_settings.dart';
import '../common/adaptive.dart';
import '../common/korean_text.dart';
import '../list/script_list_screen.dart';
import '../settings/settings_screen.dart';
import 'collection_name_dialog.dart';

/// 모음 탭. 전체와 직접 만든 모음을 그리드나 목록으로 보여 주고, 모음을 만들고 관리한다.
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

enum _Action { rename, delete }

/// 전체·모음 한 칸. 그리드 카드와 목록 줄이 같은 내용을 쓴다.
typedef _Entry = ({IconData icon, String name, int? count, VoidCallback onTap, VoidCallback? onLongPress});

class _CollectionsScreenState extends State<CollectionsScreen> {
  Stream<List<CollectionSummary>>? _collections;
  Stream<int>? _total;
  Stream<int>? _favorites;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = AppScope.of(context).repo;
    _collections ??= repo.watchCollections();
    _total ??= repo.watchScriptCount();
    _favorites ??= repo.watchFavoriteCount();
  }

  void _open(Collection? collection, {bool favorites = false}) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ScriptListScreen(collection: collection, favorites: favorites)),
      );

  Future<void> _create(List<CollectionSummary> all) async {
    final repo = AppScope.of(context).repo;
    final name = await askCollectionName(
      context,
      title: '새 모음',
      confirmLabel: '만들기',
      takenNames: {for (final c in all) c.collection.name},
    );
    if (name != null) await repo.createCollection(name);
  }

  Future<void> _manage(CollectionSummary item, List<CollectionSummary> all) async {
    final repo = AppScope.of(context).repo;
    final collection = item.collection;
    final action = await showModalBottomSheet<_Action>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(collection.name, style: theme.textTheme.titleLarge),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('이름 바꾸기'),
                  onTap: () => Navigator.pop(context, _Action.rename),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  title: Text('삭제', style: TextStyle(color: scheme.error)),
                  onTap: () => Navigator.pop(context, _Action.delete),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _Action.rename:
        final name = await askCollectionName(
          context,
          title: '이름 바꾸기',
          confirmLabel: '바꾸기',
          initial: collection.name,
          takenNames: {for (final c in all) if (c.collection.id != collection.id) c.collection.name},
        );
        if (name != null && name != collection.name) await repo.renameCollection(collection.id, name);
      case _Action.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('모음 삭제'),
            content: Text(keepWords("'${collection.name}' 모음을 삭제할까요? 모음만 지워지고 안에 있던 대본은 그대로 남아요.")),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
        if (ok == true) await repo.deleteCollection(collection.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final homeView = AppScope.of(context).homeView;
    return ListenableBuilder(
      listenable: homeView,
      builder: (context, _) {
        final grid = homeView.layout == HomeLayout.grid;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            titleSpacing: 20,
            title: Text('모음', style: theme.textTheme.headlineMedium),
            actions: [
              IconButton(
                tooltip: grid ? '목록으로 보기' : '그리드로 보기',
                icon: Icon(grid ? Icons.view_list_rounded : Icons.grid_view_rounded),
                onPressed: () => homeView.setLayout(grid ? HomeLayout.list : HomeLayout.grid),
              ),
              IconButton(
                tooltip: '설정',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<int>(
            stream: _total,
            builder: (context, totalSnap) => StreamBuilder<int>(
              stream: _favorites,
              builder: (context, favoriteSnap) => StreamBuilder<List<CollectionSummary>>(
                stream: _collections,
                builder: (context, snap) {
                  final collections = snap.data ?? const <CollectionSummary>[];
                  final entries = <_Entry>[
                    (
                      icon: Icons.library_books_outlined,
                      name: '전체',
                      count: totalSnap.data,
                      onTap: () => _open(null),
                      onLongPress: null,
                    ),
                    // 대본의 별을 누르면 저절로 모인다. 따로 넣고 빼거나 이름을 바꾸지 않는다
                    (
                      icon: Icons.star_outline_rounded,
                      name: '즐겨찾기',
                      count: favoriteSnap.data,
                      onTap: () => _open(null, favorites: true),
                      onLongPress: null,
                    ),
                    for (final c in collections)
                      (
                        icon: Icons.folder_outlined,
                        name: c.collection.name,
                        count: c.scriptCount,
                        onTap: () => _open(c.collection),
                        onLongPress: () => _manage(c, collections),
                      ),
                  ];
                  void create() => _create(collections);
                  const padding = EdgeInsets.fromLTRB(20, 4, 20, 32);
                  return LayoutBuilder(
                    builder: (context, constraints) => CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: grid
                              ? readablePadding(constraints.maxWidth, padding, maxWidth: _gridMaxWidth)
                              : readablePadding(constraints.maxWidth, padding),
                          // 넓은 창에서 카드가 한 줄로 흩어져 아래가 비지 않도록, 그리드 폭을 줄이고 세 개씩 놓는다(폰에서는 두 개)
                          sliver: grid
                              ? SliverGrid.count(
                                  crossAxisCount:
                                      (constraints.maxWidth - padding.horizontal).clamp(0.0, _gridMaxWidth) < 520 ? 2 : 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.2,
                                  children: [
                                    for (final e in entries) _CollectionCard(entry: e),
                                    _NewCollectionCard(onTap: create),
                                  ],
                                )
                              : SliverToBoxAdapter(child: _CollectionList(entries: entries, onCreate: create)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 모음 그리드가 넓어질 수 있는 최대 폭. 이 폭에 세 개씩 놓으면 카드 하나가 300쯤 된다.
const _gridMaxWidth = 960.0;

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: entry.onTap,
        onLongPress: entry.onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(entry.icon, size: 22, color: scheme.primary),
              const Spacer(),
              Text(
                entry.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
              ),
              const SizedBox(height: 2),
              Text(
                entry.count == null ? '' : '${entry.count}편',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewCollectionCard extends StatelessWidget {
  const _NewCollectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(height: 6),
              Text('새 모음', style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 목록 보기. 설정 화면처럼 카드 하나 안에 줄로 늘어놓는다.
class _CollectionList extends StatelessWidget {
  const _CollectionList({required this.entries, required this.onCreate});

  final List<_Entry> entries;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget leading(IconData icon, {bool outlined = false}) => Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: outlined ? null : scheme.primaryContainer,
            border: outlined ? Border.all(color: scheme.outlineVariant) : null,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: outlined ? scheme.onSurfaceVariant : scheme.onPrimaryContainer),
        );
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 4);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final e in entries) ...[
            ListTile(
              contentPadding: padding,
              leading: leading(e.icon),
              title: Text(
                e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.count == null ? '' : '${e.count}편',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
              onTap: e.onTap,
              onLongPress: e.onLongPress,
            ),
            const Divider(height: 1, indent: 70),
          ],
          ListTile(
            contentPadding: padding,
            leading: leading(Icons.add_rounded, outlined: true),
            title: Text('새 모음', style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}
