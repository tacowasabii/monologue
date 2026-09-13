import 'package:flutter/material.dart';

/// 구역 제목과 오른쪽으로 이어지는 가는 선
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 4 : 32, bottom: 14),
      child: Row(
        children: [
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
