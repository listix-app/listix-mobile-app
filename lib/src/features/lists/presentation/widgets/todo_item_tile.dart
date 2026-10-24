import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/todo_item.dart';

class TodoItemTile extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final Color? activeColor;
  final int? reorderIndex;

  const TodoItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
    this.onLongPress,
    this.activeColor,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final checkboxColor = activeColor ?? AppColors.primary;
    final tileBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark
        ? AppColors.borderDark.withValues(alpha: 0.7)
        : AppColors.borderLight.withValues(alpha: 0.7);
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textDoneColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.deleteBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.delete,
          size: 22,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.deleteBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.delete,
          size: 22,
        ),
      ),
      child: AnimatedOpacity(
        opacity: item.isCompleted ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle();
              },
              onLongPress: onLongPress != null
                  ? () {
                      HapticFeedback.mediumImpact();
                      onLongPress!();
                    }
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Semantics(
                      checked: item.isCompleted,
                      label: item.title,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: item.isCompleted
                              ? checkboxColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.isCompleted
                                ? checkboxColor
                                : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMuted),
                            width: 1.8,
                          ),
                        ),
                        child: item.isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: item.isCompleted
                              ? textDoneColor
                              : textTitleColor,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: textDoneColor,
                          decorationThickness: 1.5,
                        ),
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (item.isCompleted) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        key: ValueKey('delete_${item.id}'),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                        tooltip: 'Eliminar',
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        padding: const EdgeInsets.all(8),
                        onPressed: onDelete,
                      ),
                    ],
                    if (onEdit != null && !item.isCompleted) ...[
                      const SizedBox(width: 2),
                      IconButton(
                        key: ValueKey('edit_${item.id}'),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                        tooltip: 'Editar',
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        padding: const EdgeInsets.all(8),
                        onPressed: onEdit,
                      ),
                    ],
                    if (reorderIndex != null) ...[
                      const SizedBox(width: 2),
                      ReorderableDragStartListener(
                        index: reorderIndex!,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ] else if (!item.isCompleted) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.textMutedDark.withValues(alpha: 0.4)
                              : AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
