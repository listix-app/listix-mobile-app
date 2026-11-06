import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_context.dart';
import '../../domain/entities/list_type.dart';
import 'list_type_presentation.dart';

class ListTypePicker extends StatelessWidget {
  final AppStrings strings;
  final ValueChanged<ListType> onSelected;

  const ListTypePicker({
    super.key,
    required this.strings,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final type in ListType.values)
          _ListTypeCard(
            key: Key('list_type_${type.name}'),
            type: type,
            strings: strings,
            onTap: () => onSelected(type),
          ),
      ],
    );
  }
}

class _ListTypeCard extends StatelessWidget {
  final ListType type;
  final AppStrings strings;
  final VoidCallback onTap;

  const _ListTypeCard({
    super.key,
    required this.type,
    required this.strings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final bodyColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type.icon,
                  color: isDark
                      ? AppColors.primaryLight
                      : AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.listTypeName(type),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.listTypeDescription(type),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: bodyColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: bodyColor),
            ],
          ),
        ),
      ),
    );
  }
}
