import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SyncIndicator extends StatelessWidget {
  final bool isSynced;
  final double size;
  final bool showTooltip;

  const SyncIndicator({
    super.key,
    required this.isSynced,
    this.size = 7.0,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isSynced) {
      return const SizedBox.shrink();
    }

    final indicator = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.syncPending,
        shape: BoxShape.circle,
      ),
    );

    if (!showTooltip) {
      return indicator;
    }

    return Tooltip(message: 'Pendiente de sincronizar', child: indicator);
  }
}
