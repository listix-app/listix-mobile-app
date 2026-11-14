import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_context.dart';
import '../../domain/entities/list_type.dart';
import '../../domain/entities/todo_item.dart';
import 'item_card_base.dart';
import 'list_type_presentation.dart';

class TodoItemTile extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final Color? activeColor;
  final int? reorderIndex;
  final ListType listType;
  final AppStrings? strings;
  final List<String> attributeNames;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenLink;
  final void Function(double delta)? onAdjustQuantity;
  final void Function(String subtaskId)? onToggleSubtask;

  const TodoItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
    this.onLongPress,
    this.activeColor,
    this.reorderIndex,
    this.listType = ListType.custom,
    this.strings,
    this.attributeNames = const [],
    this.onToggleFavorite,
    this.onOpenLink,
    this.onAdjustQuantity,
    this.onToggleSubtask,
  });

  AppStrings get _tr => strings ?? AppStrings(AppLanguage.es);
  Color get _color => activeColor ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return switch (listType) {
      ListType.market => MarketItemTile(tile: this),
      ListType.shopping => ShoppingItemTile(tile: this),
      ListType.options => OptionItemTile(tile: this),
      ListType.tasks => TaskItemTile(tile: this),
      ListType.custom => CustomItemTile(tile: this),
    };
  }
}

String formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

Color priorityColor(ItemPriority priority) => switch (priority) {
  ItemPriority.high => AppColors.delete,
  ItemPriority.medium => AppColors.syncPending,
  ItemPriority.low => AppColors.offline,
};

class _CheckableItemCard extends StatelessWidget {
  final TodoItemTile tile;
  final Widget? leadingExtra;
  final List<Widget> content;
  final List<Widget> actions;
  final bool extraDimmed;

  const _CheckableItemCard({
    required this.tile,
    required this.content,
    this.leadingExtra,
    this.actions = const [],
    this.extraDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final item = tile.item;
    final checkbox = ItemCheckbox(
      isChecked: item.isCompleted,
      label: item.title,
      activeColor: tile._color,
    );
    return ItemCardBase(
      itemId: item.id,
      isDimmed: item.isCompleted || extraDimmed,
      isChecked: item.isCompleted,
      showDeleteAction: item.isCompleted,
      showEditAction: !item.isCompleted,
      showIdleDragHandle: !item.isCompleted,
      reorderIndex: tile.reorderIndex,
      onTap: tile.onToggle,
      onDelete: tile.onDelete,
      deleteTooltip: tile._tr.delete,
      editTooltip: tile._tr.editAction,
      onEdit: tile.onEdit,
      onLongPress: tile.onLongPress,
      leading: leadingExtra == null
          ? checkbox
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [checkbox, const SizedBox(width: 10), leadingExtra!],
            ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemTitle(text: item.title, isStruckThrough: item.isCompleted),
          ...content,
        ],
      ),
      actions: actions,
    );
  }
}

class _DescriptionLine extends StatelessWidget {
  final String text;
  final int maxLines;

  const _DescriptionLine(this.text, {this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.5,
          height: 1.3,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class MarketItemTile extends StatelessWidget {
  final TodoItemTile tile;

  const MarketItemTile({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    final item = tile.item;
    final tr = tile._tr;
    final quantity = item.quantity;
    final price = item.price;
    final canStepQuantity = tile.onAdjustQuantity != null && !item.isCompleted;
    return _CheckableItemCard(
      tile: tile,
      content: [
        ItemMetaLine(
          entries: [
            if (quantity != null)
              ('${formatNumber(quantity)} ${item.unit ?? ''}'.trim(), null),
            if (price != null) (tr.formatPrice(price), null),
          ],
        ),
      ],
      actions: [
        if (canStepQuantity)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: ValueKey('qty_dec_${item.id}'),
                tooltip: tr.decreaseQuantity,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                onPressed: () => tile.onAdjustQuantity!(-1),
              ),
              IconButton(
                key: ValueKey('qty_inc_${item.id}'),
                tooltip: tr.increaseQuantity,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                onPressed: () => tile.onAdjustQuantity!(1),
              ),
            ],
          ),
      ],
    );
  }
}

class ShoppingItemTile extends StatelessWidget {
  final TodoItemTile tile;

  const ShoppingItemTile({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    final item = tile.item;
    final tr = tile._tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = item.price;
    final isDiscarded = item.evaluation == ItemEvaluation.discarded;
    return _CheckableItemCard(
      tile: tile,
      extraDimmed: isDiscarded,
      leadingExtra: item.imageUrl == null
          ? null
          : ItemThumbnail(
              key: ValueKey('thumb_${item.id}'),
              imageUrl: item.imageUrl,
              fallbackIcon: Icons.shopping_bag_outlined,
            ),
      content: [
        ItemMetaLine(
          entries: [
            if (isDiscarded) (tr.statusDiscarded, AppColors.offline),
            if (item.store != null) (item.store!, null),
            if (item.priority != null)
              (tr.priorityName(item.priority!), priorityColor(item.priority!)),
          ],
        ),
      ],
      actions: [
        if (price != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              tr.formatPrice(price),
              key: ValueKey('price_${item.id}'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        if (tile.onOpenLink != null && item.url != null)
          IconButton(
            key: ValueKey('link_${item.id}'),
            icon: const Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            tooltip: tr.openLink,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: const EdgeInsets.all(8),
            onPressed: tile.onOpenLink,
          ),
      ],
    );
  }
}

class OptionItemTile extends StatelessWidget {
  final TodoItemTile tile;

  const OptionItemTile({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    final item = tile.item;
    final tr = tile._tr;
    final mutedColor = context.mutedTextColor;
    final names = tile.attributeNames.isEmpty
        ? item.attributes.keys.toList()
        : tile.attributeNames;
    final attributeEntries = [
      for (final name in names)
        if ((item.attributes[name] ?? '').isNotEmpty)
          ('$name: ${item.attributes[name]}', null),
    ];
    final evaluation = item.evaluation;
    final description = item.description ?? item.notes;

    return ItemCardBase(
      itemId: item.id,
      isChecked: item.isChosen,
      isHighlighted: item.isChosen,
      isDimmed: evaluation == ItemEvaluation.discarded,
      showIdleDragHandle: true,
      reorderIndex: tile.reorderIndex,
      onTap: tile.onEdit ?? tile.onToggle,
      onDelete: tile.onDelete,
      deleteTooltip: tile._tr.delete,
      editTooltip: tile._tr.editAction,
      onEdit: tile.onEdit,
      onLongPress: tile.onLongPress,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkResponse(
            key: const Key('chosen_indicator'),
            onTap: tile.onToggle,
            radius: 22,
            child: Tooltip(
              message: item.isChosen ? tr.unmarkChosen : tr.markChosen,
              child: Icon(
                item.isChosen
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 24,
                color: item.isChosen ? tile._color : mutedColor,
              ),
            ),
          ),
          if (item.imageUrl != null) ...[
            const SizedBox(width: 10),
            ItemThumbnail(
              key: ValueKey('thumb_${item.id}'),
              imageUrl: item.imageUrl,
              fallbackIcon: Icons.image_outlined,
            ),
          ],
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemTitle(text: item.title),
          if (description != null) _DescriptionLine(description, maxLines: 2),
          ItemMetaLine(
            entries: [
              if (item.isChosen) (tr.chosenBadge, AppColors.primary),
              if (item.price != null) (tr.formatPrice(item.price!), null),
              if (item.rating != null)
                ('★ ${item.rating}/5', const Color(0xFFF59E0B)),
              if (evaluation != null && evaluation != ItemEvaluation.pending)
                (tr.evaluationName(evaluation), null),
              ...attributeEntries,
              if ((item.pros ?? '').isNotEmpty)
                ('+ ${item.pros}', AppColors.primary),
              if ((item.cons ?? '').isNotEmpty)
                ('- ${item.cons}', AppColors.delete),
            ],
          ),
        ],
      ),
      actions: [
        if (tile.onOpenLink != null && item.url != null)
          IconButton(
            key: ValueKey('link_${item.id}'),
            icon: const Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            tooltip: tr.openLink,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: const EdgeInsets.all(8),
            onPressed: tile.onOpenLink,
          ),
        if (tile.onToggleFavorite != null)
          IconButton(
            key: ValueKey('favorite_${item.id}'),
            icon: Icon(
              item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 22,
              color: item.isFavorite ? AppColors.star : mutedColor,
            ),
            tooltip: item.isFavorite ? tr.removeFavorite : tr.addFavorite,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: const EdgeInsets.all(8),
            onPressed: tile.onToggleFavorite,
          ),
      ],
    );
  }
}

class TaskItemTile extends StatelessWidget {
  final TodoItemTile tile;

  const TaskItemTile({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    final item = tile.item;
    final tr = tile._tr;
    final dueDate = item.dueDate;
    final today = DateTime.now();
    final isOverdue =
        dueDate != null &&
        !item.isCompleted &&
        DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
        ).isBefore(DateTime(today.year, today.month, today.day));
    final description = item.description ?? item.notes;
    final subtasks = item.subtasks;
    final completedSubtasks = subtasks.where((s) => s.isCompleted).length;

    return _CheckableItemCard(
      tile: tile,
      content: [
        if (description != null) _DescriptionLine(description),
        ItemMetaLine(
          entries: [
            if (item.isInProgress) (tr.inProgressLabel, AppColors.primary),
            if (item.priority != null)
              (tr.priorityName(item.priority!), priorityColor(item.priority!)),
            if (dueDate != null)
              (
                MaterialLocalizations.of(context).formatMediumDate(dueDate),
                isOverdue ? AppColors.delete : null,
              ),
            if (subtasks.isNotEmpty)
              ('$completedSubtasks/${subtasks.length}', null),
          ],
        ),
        if (subtasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final subtask in subtasks)
                  InkWell(
                    key: ValueKey('subtask_${item.id}_${subtask.id}'),
                    onTap: tile.onToggleSubtask == null
                        ? null
                        : () => tile.onToggleSubtask!(subtask.id),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            subtask.isCompleted
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 15,
                            color: subtask.isCompleted
                                ? tile._color
                                : context.mutedTextColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              subtask.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                decoration: subtask.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: context.mutedTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class CustomItemTile extends StatelessWidget {
  final TodoItemTile tile;

  const CustomItemTile({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    final description = tile.item.description ?? tile.item.notes;
    return _CheckableItemCard(
      tile: tile,
      content: [if (description != null) _DescriptionLine(description)],
    );
  }
}
