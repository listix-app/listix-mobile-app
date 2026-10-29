import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../domain/entities/list_type.dart';

extension ListTypeIcon on ListType {
  IconData get icon => switch (this) {
    ListType.market => Icons.shopping_basket_outlined,
    ListType.shopping => Icons.shopping_bag_outlined,
    ListType.options => Icons.compare_arrows_rounded,
    ListType.tasks => Icons.checklist_rounded,
    ListType.custom => Icons.dashboard_customize_outlined,
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
  };

  String emptyItemsMessageFor(ListType type) => switch (type) {
    ListType.market => emptyMarketMessage,
    ListType.shopping => emptyShoppingMessage,
    ListType.options => emptyOptionsMessage,
    ListType.tasks => emptyTasksMessage,
    ListType.custom => emptyItemsMessage,
  };
}
