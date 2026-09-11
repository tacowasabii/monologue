import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../theme.dart';

/// 점 하나와 라벨로 연습 상태를 보여준다. 연습 전은 빈 원.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final PracticeStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = statusColor(status, scheme);
    final idle = status == PracticeStatus.notStarted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: idle ? null : color,
            border: idle ? Border.all(color: color, width: 1.4) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: idle ? scheme.onSurfaceVariant : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
