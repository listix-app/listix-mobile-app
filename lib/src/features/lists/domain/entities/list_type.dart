import 'todo_item.dart';

enum ListType {
  market,
  shopping,
  options,
  tasks,
  custom;

  static const List<ListType> primaryTypes = [
    ListType.market,
    ListType.shopping,
    ListType.options,
    ListType.tasks,
  ];

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
  dueDate,
  rating;

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
    ItemSort.rating => _sorted(
      items,
      (a, b) => _nullsLast(a.rating, b.rating, (x, y) => y.compareTo(x)),
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
    ListType.options => const [
      ItemSort.manual,
      ItemSort.rating,
      ItemSort.price,
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

class ListTemplateItemSeed {
  final String titleEs;
  final String titleEn;
  final double? quantity;
  final String? unit;
  final String? category;
  final ItemPriority? priority;

  const ListTemplateItemSeed({
    required this.titleEs,
    required this.titleEn,
    this.quantity,
    this.unit,
    this.category,
    this.priority,
  });

  String title(bool isSpanish) => isSpanish ? titleEs : titleEn;
}

class ListTemplate {
  final String id;
  final ListType type;
  final String nameEs;
  final String nameEn;
  final List<String> attributeNamesEs;
  final List<String> attributeNamesEn;
  final List<ListTemplateItemSeed> starterItems;

  const ListTemplate({
    required this.id,
    required this.type,
    required this.nameEs,
    required this.nameEn,
    this.attributeNamesEs = const [],
    this.attributeNamesEn = const [],
    this.starterItems = const [],
  });

  String name(bool isSpanish) => isSpanish ? nameEs : nameEn;

  List<String> attributeNames(bool isSpanish) =>
      isSpanish ? attributeNamesEs : attributeNamesEn;

  static const List<ListTemplate> all = [
    ListTemplate(
      id: 'market_weekly',
      type: ListType.market,
      nameEs: 'Mercado semanal',
      nameEn: 'Weekly groceries',
      starterItems: [
        ListTemplateItemSeed(
          titleEs: 'Leche',
          titleEn: 'Milk',
          quantity: 2,
          unit: 'l',
          category: 'dairy',
        ),
        ListTemplateItemSeed(
          titleEs: 'Pan',
          titleEn: 'Bread',
          quantity: 1,
          unit: 'pack',
          category: 'bakery',
        ),
        ListTemplateItemSeed(
          titleEs: 'Frutas',
          titleEn: 'Fruit',
          quantity: 1,
          unit: 'kg',
          category: 'produce',
        ),
      ],
    ),
    ListTemplate(
      id: 'market_pantry',
      type: ListType.market,
      nameEs: 'Despensa básica',
      nameEn: 'Pantry essentials',
      starterItems: [
        ListTemplateItemSeed(
          titleEs: 'Arroz',
          titleEn: 'Rice',
          quantity: 1,
          unit: 'kg',
          category: 'pantry',
        ),
        ListTemplateItemSeed(
          titleEs: 'Café',
          titleEn: 'Coffee',
          quantity: 1,
          unit: 'un',
          category: 'beverages',
        ),
      ],
    ),
    ListTemplate(
      id: 'shopping_tech',
      type: ListType.shopping,
      nameEs: 'Compras de tecnología',
      nameEn: 'Tech shopping',
      starterItems: [
        ListTemplateItemSeed(
          titleEs: 'Audífonos',
          titleEn: 'Headphones',
          priority: ItemPriority.high,
        ),
        ListTemplateItemSeed(
          titleEs: 'Cargador USB-C',
          titleEn: 'USB-C Charger',
          priority: ItemPriority.medium,
        ),
      ],
    ),
    ListTemplate(
      id: 'shopping_home',
      type: ListType.shopping,
      nameEs: 'Compras para el hogar',
      nameEn: 'Home shopping',
      starterItems: [
        ListTemplateItemSeed(
          titleEs: 'Lámpara de escritorio',
          titleEn: 'Desk lamp',
          priority: ItemPriority.medium,
        ),
      ],
    ),
    ListTemplate(
      id: 'options_universities',
      type: ListType.options,
      nameEs: 'Comparar universidades',
      nameEn: 'Compare universities',
      attributeNamesEs: [
        'Matrícula',
        'Modalidad',
        'Ubicación',
        'Duración',
        'Acreditación',
      ],
      attributeNamesEn: [
        'Tuition',
        'Modality',
        'Location',
        'Duration',
        'Accreditation',
      ],
    ),
    ListTemplate(
      id: 'options_products',
      type: ListType.options,
      nameEs: 'Comparar productos',
      nameEn: 'Compare products',
      attributeNamesEs: ['Marca', 'Garantía', 'Calidad'],
      attributeNamesEn: ['Brand', 'Warranty', 'Quality'],
    ),
    ListTemplate(
      id: 'tasks_daily',
      type: ListType.tasks,
      nameEs: 'Tareas de la semana',
      nameEn: 'Weekly tasks',
      starterItems: [
        ListTemplateItemSeed(
          titleEs: 'Planificar prioridades',
          titleEn: 'Plan priorities',
          priority: ItemPriority.high,
        ),
      ],
    ),
    ListTemplate(
      id: 'tasks_project',
      type: ListType.tasks,
      nameEs: 'Checklist de proyecto',
      nameEn: 'Project checklist',
      starterItems: [
        ListTemplateItemSeed(
          titleEs: 'Definir entregables',
          titleEn: 'Define deliverables',
          priority: ItemPriority.high,
        ),
      ],
    ),
  ];

  static List<ListTemplate> templatesFor(ListType type) =>
      all.where((template) => template.type == type).toList();
}
