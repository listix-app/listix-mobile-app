import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Un micro-indicador sutil que avisa si el item o la lista aún no está sincronizado.
/// Diseñado para ocupar un espacio reservado mínimo sin distraer al usuario.
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

    if (!showTooltip) return indicator;

    return Tooltip(
      message: 'Pendiente de sincronizar (guardado local)',
      waitDuration: const Duration(milliseconds: 300),
      child: indicator,
    );
  }
}
