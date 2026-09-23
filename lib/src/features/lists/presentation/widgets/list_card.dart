import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/collaborator.dart';
import '../../domain/entities/shopping_list.dart';

class ListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final AppStrings? strings;

  const ListCard({
    super.key,
    required this.list,
    required this.onTap,
    this.onDelete,
    this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final tr = strings ?? AppStrings(AppLanguage.es);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badgeText = list.totalCount == 0
        ? tr.noItemsBadge
        : list.pendingCount == 0
        ? tr.allDoneBadge
        : tr.pendingBadge(list.progressText);

    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textTitleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final badgeBg = list.pendingCount == 0 && list.totalCount > 0
        ? AppColors.syncDone.withValues(alpha: 0.16)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
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
                            ? AppColors.syncDone.withValues(alpha: 0.35)
                            : borderColor,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: list.pendingCount == 0 && list.totalCount > 0
                            ? AppColors.syncDone
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
                    fontSize: 9,
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
