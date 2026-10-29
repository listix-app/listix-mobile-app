enum ListType {
  market,
  shopping,
  options,
  tasks,
  custom;

  static ListType fromName(String? name) => ListType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => ListType.custom,
  );

  bool get isGroupedByCategory => this == ListType.market;
  bool get tracksCompletion => this != ListType.options;
}

enum ItemPriority {
  low,
  medium,
  high;

  static ItemPriority? fromName(String? name) {
    for (final priority in ItemPriority.values) {
      if (priority.name == name) return priority;
    }
    return null;
  }
}

enum ItemEvaluation {
  pending,
  evaluated,
  discarded;

  static ItemEvaluation? fromName(String? name) {
    for (final evaluation in ItemEvaluation.values) {
      if (evaluation.name == name) return evaluation;
    }
    return null;
  }
}

abstract final class MarketCatalog {
  static const String uncategorized = 'other';

  static const List<String> categories = [
    'produce',
    'dairy',
    'meat',
    'bakery',
    'pantry',
    'beverages',
    'cleaning',
    uncategorized,
  ];

  static const List<String> units = ['un', 'kg', 'g', 'l', 'ml', 'pack'];
}
