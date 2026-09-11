import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../../domain/script_filter.dart';
import '../common/pill_chip.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.filter, required this.tags, required this.onChanged});

  final ScriptFilter filter;
  final List<String> tags;
  final ValueChanged<ScriptFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      PillChip(
        label: '즐겨찾기',
        icon: filter.favoritesOnly ? Icons.star_rounded : Icons.star_outline_rounded,
        selected: filter.favoritesOnly,
        onSelected: (v) => onChanged(filter.copyWith(favoritesOnly: v)),
      ),
      _ChoiceChip<Gender>(
        label: '성별',
        value: filter.gender,
        options: Gender.values.where((g) => g != Gender.any).toList(),
        labelOf: (g) => g.label,
        onChanged: (g) => onChanged(filter.copyWith(gender: () => g)),
      ),
      _ChoiceChip<AgeRange>(
        label: '나이대',
        value: filter.ageRange,
        options: AgeRange.values.where((a) => a != AgeRange.any).toList(),
        labelOf: (a) => a.label,
        onChanged: (a) => onChanged(filter.copyWith(ageRange: () => a)),
      ),
      _ChoiceChip<PracticeStatus>(
        label: '연습 상태',
        value: filter.status,
        options: PracticeStatus.values,
        labelOf: (s) => s.label,
        onChanged: (s) => onChanged(filter.copyWith(status: () => s)),
      ),
      if (tags.isNotEmpty || filter.tag != null)
        _ChoiceChip<String>(
          label: '태그',
          value: filter.tag,
          options: tags,
          labelOf: (t) => '#$t',
          onChanged: (t) => onChanged(filter.copyWith(tag: () => t)),
        ),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }
}

class _Pick<T> {
  const _Pick(this.value);

  final T? value;
}

/// 탭하면 바텀시트에서 `전체` 또는 값 하나를 고르는 칩.
class _ChoiceChip<T> extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<_Pick<T>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final accent = theme.colorScheme.primary;
        Widget option(String text, T? v) {
          final on = v == value;
          return ListTile(
            title: Text(text, style: on ? TextStyle(color: accent, fontWeight: FontWeight.w700) : null),
            trailing: on ? Icon(Icons.check_rounded, color: accent) : null,
            onTap: () => Navigator.pop(context, _Pick<T>(v)),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(label, style: theme.textTheme.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    option('전체', null),
                    for (final o in options) option(labelOf(o), o),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) onChanged(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    final selected = current != null;
    return PillChip(
      label: current != null ? labelOf(current) : label,
      selected: selected,
      trailingIcon: selected ? Icons.close_rounded : Icons.expand_more_rounded,
      // 기본 안내 문구는 "삭제"라서, ▾(목록 열기)도 삭제로 읽힌다
      trailingTooltip: selected ? '$label 해제' : '$label 선택',
      onTrailing: selected ? () => onChanged(null) : () => _open(context),
      onSelected: (_) => _open(context),
    );
  }
}
