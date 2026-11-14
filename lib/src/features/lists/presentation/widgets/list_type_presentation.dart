import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/list_type.dart';
import '../../domain/entities/shopping_list.dart';

extension ListTypeIcon on ListType {
  IconData get icon => switch (this) {
    ListType.market => Icons.shopping_basket_outlined,
    ListType.shopping => Icons.shopping_bag_outlined,
    ListType.options => Icons.compare_arrows_rounded,
    ListType.tasks => Icons.checklist_rounded,
    ListType.custom => Icons.dashboard_customize_outlined,
  };

  Color get accentColor => switch (this) {
    ListType.market => AppColors.primary,
    ListType.shopping => const Color(0xFF2563EB),
    ListType.options => const Color(0xFF7C3AED),
    ListType.tasks => const Color(0xFFD97706),
    ListType.custom => AppColors.primary,
  };
}

extension ListTypeStrings on AppStrings {
  String listTypeName(ListType type) => switch (type) {
    ListType.market => listTypeMarket,
    ListType.shopping => listTypeShopping,
    ListType.options => listTypeOptions,
    ListType.tasks => listTypeTasks,
    ListType.custom => listTypeCustom,
  };

  String listTypeDescription(ListType type) => switch (type) {
    ListType.market => listTypeMarketDesc,
    ListType.shopping => listTypeShoppingDesc,
    ListType.options => listTypeOptionsDesc,
    ListType.tasks => listTypeTasksDesc,
    ListType.custom => listTypeCustomDesc,
  };

  String categoryName(String? key) => switch (key) {
    'produce' => categoryProduce,
    'dairy' => categoryDairy,
    'meat' => categoryMeat,
    'bakery' => categoryBakery,
    'pantry' => categoryPantry,
    'beverages' => categoryBeverages,
    'cleaning' => categoryCleaning,
    _ => categoryOther,
  };

  String priorityName(ItemPriority priority) => switch (priority) {
    ItemPriority.low => priorityLow,
    ItemPriority.medium => priorityMedium,
    ItemPriority.high => priorityHigh,
  };

  String evaluationName(ItemEvaluation evaluation) => switch (evaluation) {
    ItemEvaluation.pending => evaluationPending,
    ItemEvaluation.evaluated => evaluationEvaluated,
    ItemEvaluation.discarded => evaluationDiscarded,
  };

  String sortName(ItemSort sort) => switch (sort) {
    ItemSort.manual => sortManual,
    ItemSort.price => sortPrice,
    ItemSort.priority => sortPriority,
    ItemSort.dueDate => sortDueDate,
    ItemSort.rating => sortRating,
  };

  String emptyItemsMessageFor(ListType type) => switch (type) {
    ListType.market => emptyMarketMessage,
    ListType.shopping => emptyShoppingMessage,
    ListType.options => emptyOptionsMessage,
    ListType.tasks => emptyTasksMessage,
    ListType.custom => emptyItemsMessage,
  };

  String? listCardSecondarySummary(ShoppingList list) {
    if ((list.type == ListType.market || list.type == ListType.shopping) &&
        list.totalPrice > 0) {
      return shoppingTotal(formatPrice(list.totalPrice));
    }
    if (list.type == ListType.options && list.chosenOption != null) {
      return '$chosenBadge: ${list.chosenOption!.title}';
    }
    if (list.type == ListType.tasks &&
        list.items.any((item) => item.isInProgress && !item.isCompleted)) {
      return inProgressLabel;
    }
    return null;
  }
}
