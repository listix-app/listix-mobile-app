import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/shopping_list.dart';

class ListGridCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStar;
  final AppStrings? strings;

  const ListGridCard({
    super.key,
    required this.list,
    required this.onTap,
    this.onDelete,
    this.onToggleStar,
    this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final tr = strings ?? AppStrings(AppLanguage.es);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = list.isStarred
        ? const Color(0xFFFFB800).withValues(alpha: 0.5)
        : (isDark ? AppColors.borderDark : AppColors.borderLight);
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSubColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final badgeText = list.totalCount == 0
        ? tr.noItemsBadge
        : list.pendingCount == 0
        ? tr.allDoneBadge
        : tr.pendingBadge(list.progressText);

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: list.isStarred ? 1.5 : 1.0),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: list.pendingCount == 0 && list.totalCount > 0
                            ? AppColors.syncDone.withValues(alpha: 0.16)
                            : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: list.pendingCount == 0 && list.totalCount > 0
                              ? AppColors.syncDone
                              : textSubColor,
                        ),
                      ),
                    ),
                  ),
                  if (onToggleStar != null)
                    IconButton(
                      icon: Icon(
                        list.isStarred
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 20,
                        color: list.isStarred
                            ? const Color(0xFFFFB800)
                            : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMuted),
                      ),
                      tooltip: list.isStarred ? tr.unstarList : tr.starList,
                      onPressed: onToggleStar,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                list.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: textTitleColor,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: list.completionProgress,
                      backgroundColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        list.completionProgress == 1.0
                            ? AppColors.syncDone
                            : AppColors.primary,
                      ),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${list.completedCount}/${list.totalCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSubColor,
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.delete,
                          ),
                          tooltip: tr.delete,
                          onPressed: onDelete,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
