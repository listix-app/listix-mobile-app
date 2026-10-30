import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_context.dart';

class ItemCardBase extends StatelessWidget {
  final String itemId;
  final bool isDimmed;
  final bool showDeleteAction;
  final bool showEditAction;
  final bool isHighlighted;
  final Widget leading;
  final Widget content;
  final List<Widget> actions;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String deleteTooltip;
  final String editTooltip;
  final bool? isChecked;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final int? reorderIndex;
  final bool showIdleDragHandle;

  const ItemCardBase({
    super.key,
    required this.itemId,
    required this.leading,
    required this.content,
    required this.onTap,
    required this.onDelete,
    required this.deleteTooltip,
    required this.editTooltip,
    this.isChecked,
    this.isDimmed = false,
    this.showDeleteAction = false,
    this.showEditAction = true,
    this.isHighlighted = false,
    this.actions = const [],
    this.onEdit,
    this.onLongPress,
    this.reorderIndex,
    this.showIdleDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = context.mutedTextColor;
    final borderColor = isHighlighted
        ? AppColors.primary
        : (isDark
              ? AppColors.borderDark.withValues(alpha: 0.7)
              : AppColors.borderLight.withValues(alpha: 0.7));

    return Dismissible(
      key: Key(itemId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      background: const _DeleteBackground(),
      secondaryBackground: const _DeleteBackground(),
      child: AnimatedOpacity(
        opacity: isDimmed ? 0.45 : 1.0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isHighlighted ? 1.5 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              checked: isChecked,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onLongPress!();
                      },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Expanded(child: content),
                      ...actions,
                      if (showDeleteAction)
                        _ActionButton(
                          key: ValueKey('delete_$itemId'),
                          icon: Icons.delete_outline_rounded,
                          iconSize: 19,
                          color: mutedColor,
                          tooltip: deleteTooltip,
                          onPressed: onDelete,
                        ),
                      if (onEdit != null && showEditAction)
                        _ActionButton(
                          key: ValueKey('edit_$itemId'),
                          icon: Icons.edit_outlined,
                          iconSize: 18,
                          color: mutedColor,
                          tooltip: editTooltip,
                          onPressed: onEdit!,
                        ),
                      if (reorderIndex != null)
                        ReorderableDragStartListener(
                          index: reorderIndex!,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.drag_handle_rounded,
                              size: 20,
                              color: mutedColor,
                            ),
                          ),
                        )
                      else if (showIdleDragHandle)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            size: 18,
                            color: mutedColor.withValues(alpha: 0.45),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: iconSize, color: color),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: const EdgeInsets.all(8),
      onPressed: onPressed,
    );
  }
}

class ItemCheckbox extends StatelessWidget {
  final bool isChecked;
  final String label;
  final Color activeColor;

  const ItemCheckbox({
    super.key,
    required this.isChecked,
    required this.label,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isChecked,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isChecked ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isChecked ? activeColor : (context.mutedTextColor),
            width: 1.8,
          ),
        ),
        child: isChecked
            ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
            : null,
      ),
    );
  }
}

class ItemTitle extends StatelessWidget {
  final String text;
  final bool isStruckThrough;

  const ItemTitle({
    super.key,
    required this.text,
    this.isStruckThrough = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doneColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: isStruckThrough
            ? doneColor
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        decoration: isStruckThrough
            ? TextDecoration.lineThrough
            : TextDecoration.none,
        decorationColor: doneColor,
        decorationThickness: 1.5,
      ),
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class ItemMetaLine extends StatelessWidget {
  final List<(String, Color?)> entries;

  const ItemMetaLine({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Wrap(
        spacing: 10,
        runSpacing: 2,
        children: [
          for (final (text, color) in entries)
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: color == null ? FontWeight.w400 : FontWeight.w600,
                color: color ?? mutedColor,
              ),
            ),
        ],
      ),
    );
  }
}

class ItemThumbnail extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double size;

  const ItemThumbnail({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholder = Container(
      width: size,
      height: size,
      color: isDark ? AppColors.surfaceDark : AppColors.primarySubtle,
      child: Icon(
        fallbackIcon,
        size: size * 0.5,
        color: context.mutedTextColor,
      ),
    );
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? placeholder
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
