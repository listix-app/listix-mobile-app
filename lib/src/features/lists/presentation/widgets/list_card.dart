import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/collaborator.dart';
import '../../domain/entities/list_type.dart';
import '../../domain/entities/shopping_list.dart';
import 'list_type_presentation.dart';

class ListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final VoidCallback? onToggleStar;
  final AppStrings? strings;
  final int? reorderIndex;

  const ListCard({
    super.key,
    required this.list,
    required this.onTap,
    this.onArchive,
    this.onUnarchive,
    this.onToggleStar,
    this.strings,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final tr = strings ?? AppStrings(AppLanguage.es);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badgeText = list.totalCount == 0
        ? tr.noItemsBadge
        : list.type == ListType.options
        ? tr.optionsCount(list.totalCount)
        : list.pendingCount == 0
        ? tr.allDoneBadge
        : tr.pendingBadge(list.progressText);

    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = list.isStarred
        ? AppColors.star.withValues(alpha: 0.5)
        : (isDark ? AppColors.borderDark : AppColors.borderLight);
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final listColor = list.color != null
        ? Color(list.color!)
        : AppColors.primary;
    final badgeBg = list.pendingCount == 0 && list.totalCount > 0
        ? listColor.withValues(alpha: 0.16)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    final card = Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: list.isStarred ? 1.5 : 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (list.color != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(list.color!),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      list.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textTitleColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onArchive != null)
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, size: 20),
                      tooltip: tr.archiveListAction,
                      onPressed: onArchive,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  if (onUnarchive != null)
                    IconButton(
                      icon: const Icon(Icons.unarchive_outlined, size: 20),
                      tooltip: tr.unarchiveListAction,
                      onPressed: onUnarchive,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  if (onToggleStar != null)
                    IconButton(
                      icon: Icon(
                        list.isStarred
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: list.isStarred
                            ? AppColors.star
                            : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMuted),
                      ),
                      tooltip: list.isStarred ? tr.unstarList : tr.starList,
                      onPressed: onToggleStar,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  const SizedBox(width: 4),
                  if (reorderIndex != null)
                    ReorderableDragStartListener(
                      index: reorderIndex!,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        size: 18,
                        color:
                            (isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMuted)
                                .withValues(alpha: 0.45),
                      ),
                    ),
                ],
              ),
              if (list.totalCount > 0 && list.type.tracksCompletion) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: list.completionProgress,
                    backgroundColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(listColor),
                    minHeight: 4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (list.type != ListType.custom) ...[
                    Icon(
                      list.type.icon,
                      key: const Key('list_type_icon'),
                      size: 18,
                      color: listColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: list.pendingCount == 0 && list.totalCount > 0
                            ? listColor.withValues(alpha: 0.35)
                            : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: list.pendingCount == 0 && list.totalCount > 0
                            ? listColor
                            : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (list.isShared) ...[
                    _CollaboratorAvatars(collaborators: list.collaborators),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (reorderIndex == null) return card;
    return ReorderableDelayedDragStartListener(
      index: reorderIndex!,
      child: card,
    );
  }
}

class _CollaboratorAvatars extends StatelessWidget {
  final List<Collaborator> collaborators;

  const _CollaboratorAvatars({required this.collaborators});

  @override
  Widget build(BuildContext context) {
    const maxVisible = 2;
    final visible = collaborators.take(maxVisible).toList();
    final remaining = collaborators.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < visible.length; i++)
          Align(
            widthFactor: 0.75,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  visible[i].initials,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        if (remaining > 0)
          Align(
            widthFactor: 0.75,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.borderLight,
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
