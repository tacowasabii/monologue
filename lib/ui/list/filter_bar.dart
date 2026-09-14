import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../domain/enums.dart';
import '../../domain/script_filter.dart';
import '../common/pill_chip.dart';

/// 시트에서 고르는 필터(성별·나이대·태그) 중 적용된 개수
int sheetFilterCount(ScriptFilter f) => [f.gender, f.ageRange, f.tag].where((v) => v != null).length;

ScriptFilter _clearSheetFilters(ScriptFilter f) =>
    f.copyWith(gender: () => null, ageRange: () => null, tag: () => null);

/// 성별·나이대·태그를 한 시트에서 고른다. 그냥 닫으면 바뀌지 않는다.
Future<void> openFilterSheet(
  BuildContext context, {
  required ScriptFilter filter,
  required List<String> tags,
  required ValueChanged<ScriptFilter> onChanged,
}) async {
  final picked = await showModalBottomSheet<ScriptFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _FilterSheet(initial: filter, tags: tags),
  );
  if (picked != null) onChanged(picked);
}

/// 검색창 오른쪽의 필터 버튼. 적용된 필터 수를 배지로 보여준다.
class FilterButton extends StatelessWidget {
  const FilterButton({super.key, required this.filter, required this.tags, required this.onChanged});

  final ScriptFilter filter;
  final List<String> tags;
  final ValueChanged<ScriptFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = sheetFilterCount(filter);
    return IconButton(
      tooltip: count == 0 ? '필터' : '필터 · $count개 적용',
      onPressed: () => openFilterSheet(context, filter: filter, tags: tags, onChanged: onChanged),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: scheme.primary,
        textColor: scheme.onPrimary,
        child: Icon(Icons.tune_rounded, color: count > 0 ? scheme.onSurface : scheme.onSurfaceVariant),
      ),
    );
  }
}

/// 시트에서 고른 필터를 알약으로 보여준다. 걸린 필터가 없으면 자리를 차지하지 않는다.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.filter, required this.tags, required this.onChanged});

  final ScriptFilter filter;
  final List<String> tags;
  final ValueChanged<ScriptFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pills = <({String label, ScriptFilter without})>[
      if (filter.gender case final g?) (label: '성별 ${g.label}', without: filter.copyWith(gender: () => null)),
      if (filter.ageRange case final a?) (label: a.label, without: filter.copyWith(ageRange: () => null)),
      if (filter.tag case final t?) (label: '#$t', without: filter.copyWith(tag: () => null)),
    ];
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: pills.isEmpty
          ? const SizedBox(width: double.infinity)
          : SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                children: [
                  for (final p in pills)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Center(
                        child: InputChip(
                          label: Text(p.label),
                          labelStyle: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: scheme.primaryContainer,
                          side: BorderSide.none,
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          deleteIconColor: scheme.onPrimaryContainer,
                          deleteButtonTooltipMessage: '${p.label} 해제',
                          onDeleted: () => onChanged(p.without),
                          onPressed: () => openFilterSheet(context, filter: filter, tags: tags, onChanged: onChanged),
                        ),
                      ),
                    ),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurfaceVariant,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
                      ),
                      onPressed: () => onChanged(_clearSheetFilters(filter)),
                      child: const Text('초기화'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.tags});

  final ScriptFilter initial;
  final List<String> tags;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ScriptFilter _draft = widget.initial;

  /// 적용 전에 결과 수를 보여주려고 초안 조건으로 따로 조회한다
  Stream<List<ScriptSummary>>? _matches;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _matches ??= AppScope.of(context).repo.watchScripts(_draft);
  }

  void _set(ScriptFilter f) => setState(() {
        _draft = f;
        _matches = AppScope.of(context).repo.watchScripts(f);
      });

  /// `전체` + 선택지. 고른 칩을 다시 누르면 `전체`로 돌아간다.
  /// [apply]는 누른 시점의 초안에 적용해서, 빌드 이후 바뀐 다른 조건을 덮어쓰지 않는다.
  List<Widget> _choices<T>(
    List<T> options,
    T? value,
    String Function(T) labelOf,
    ScriptFilter Function(ScriptFilter draft, T? v) apply,
  ) =>
      [
        PillChip(label: '전체', selected: value == null, onSelected: (_) => _set(apply(_draft, null))),
        for (final o in options)
          PillChip(
            label: labelOf(o),
            selected: o == value,
            onSelected: (_) => _set(apply(_draft, o == value ? null : o)),
          ),
      ];

  Widget _group(String title, List<Widget> chips) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: chips),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = _draft;
    // 목록에서 태그가 지워졌어도 걸려 있는 태그는 해제할 수 있게 남긴다
    final tags = [...widget.tags, if (d.tag case final t? when !widget.tags.contains(t)) t];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('필터', style: theme.textTheme.titleLarge)),
                TextButton(
                  onPressed: sheetFilterCount(d) == 0 ? null : () => _set(_clearSheetFilters(d)),
                  child: const Text('초기화'),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _group(
                      '성별',
                      _choices<Gender>(
                        Gender.values.where((g) => g != Gender.any).toList(),
                        d.gender,
                        (g) => g.label,
                        (f, g) => f.copyWith(gender: () => g),
                      ),
                    ),
                    _group(
                      '나이대',
                      _choices<AgeRange>(
                        AgeRange.values.where((a) => a != AgeRange.any).toList(),
                        d.ageRange,
                        (a) => a.label,
                        (f, a) => f.copyWith(ageRange: () => a),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '성별이나 나이대를 ‘무관’으로 둔 대본은 어느 조건에서나 함께 보여요',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    if (tags.isNotEmpty)
                      _group('태그', _choices<String>(tags, d.tag, (t) => '#$t', (f, t) => f.copyWith(tag: () => t))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<ScriptSummary>>(
              stream: _matches,
              builder: (context, snap) {
                final n = snap.data?.length;
                return FilledButton(
                  onPressed: n == 0 ? null : () => Navigator.pop(context, _draft),
                  child: Text(switch (n) {
                    null => '적용',
                    0 => '맞는 대본이 없어요',
                    _ => '대본 $n편 보기',
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
