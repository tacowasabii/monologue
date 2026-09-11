import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../../domain/script_filter.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.filter, required this.tags, required this.onChanged});

  final ScriptFilter filter;
  final List<String> tags;
  final ValueChanged<ScriptFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          FilterChip(
            label: const Text('즐겨찾기'),
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
        ].map((chip) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: chip)).toList(),
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
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(label, style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              title: const Text('전체'),
              trailing: value == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, _Pick<T>(null)),
            ),
            for (final o in options)
              ListTile(
                title: Text(labelOf(o)),
                trailing: o == value ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, _Pick<T>(o)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    final selected = current != null;
    return FilterChip(
      label: Text(current != null ? labelOf(current) : label),
      selected: selected,
      showCheckmark: false,
      deleteIcon: Icon(selected ? Icons.close : Icons.arrow_drop_down, size: 18),
      onDeleted: selected ? () => onChanged(null) : () => _open(context),
      onSelected: (_) => _open(context),
    );
  }
}
