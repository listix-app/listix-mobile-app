import 'todo_item.dart';

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

enum ItemSort {
  manual,
  price,
  priority,
  dueDate;

  List<TodoItem> apply(List<TodoItem> items) => switch (this) {
    ItemSort.manual => items,
    ItemSort.price => _sorted(
      items,
      (a, b) => _nullsLast(a.price, b.price, (x, y) => x.compareTo(y)),
    ),
    ItemSort.priority => _sorted(
      items,
      (a, b) => _nullsLast(
        a.priority,
        b.priority,
        (x, y) => y.index.compareTo(x.index),
      ),
    ),
    ItemSort.dueDate => _sorted(
      items,
      (a, b) => _nullsLast(a.dueDate, b.dueDate, (x, y) => x.compareTo(y)),
    ),
  };

  static List<TodoItem> _sorted(
    List<TodoItem> items,
    int Function(TodoItem, TodoItem) compare,
  ) => [...items]..sort(compare);

  static int _nullsLast<T>(T? a, T? b, int Function(T, T) compare) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return compare(a, b);
  }
}

extension ListTypeSorting on ListType {
  List<ItemSort> get sortOptions => switch (this) {
    ListType.shopping => const [
      ItemSort.manual,
      ItemSort.price,
      ItemSort.priority,
    ],
    ListType.tasks => const [
      ItemSort.manual,
      ItemSort.dueDate,
      ItemSort.priority,
    ],
    _ => const [ItemSort.manual],
  };

  bool get supportsFavoritesFilter => this == ListType.options;
}
