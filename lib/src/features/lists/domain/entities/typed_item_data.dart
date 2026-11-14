import 'list_type.dart';
import 'todo_item.dart';

enum ShoppingItemStatus {
  pending,
  purchased,
  discarded;

  static ShoppingItemStatus fromItem(TodoItem item) {
    if (item.evaluation == ItemEvaluation.discarded) {
      return ShoppingItemStatus.discarded;
    }
    if (item.isCompleted) {
      return ShoppingItemStatus.purchased;
    }
    return ShoppingItemStatus.pending;
  }
}

enum OptionDecisionStatus {
  considering,
  finalist,
  discarded,
  selected;

  static OptionDecisionStatus fromItem(TodoItem item) {
    if (item.isChosen) {
      return OptionDecisionStatus.selected;
    }
    return switch (item.evaluation) {
      ItemEvaluation.evaluated => OptionDecisionStatus.finalist,
      ItemEvaluation.discarded => OptionDecisionStatus.discarded,
      _ => OptionDecisionStatus.considering,
    };
  }
}

sealed class TypedItemData {
  final String id;
  final String listId;
  final String title;

  const TypedItemData({
    required this.id,
    required this.listId,
    required this.title,
  });

  ListType get listType;
}

class MarketItemData extends TypedItemData {
  final double? quantity;
  final String? unit;
  final String category;
  final double? estimatedPrice;
  final bool isPurchased;
  final String? notes;

  const MarketItemData({
    required super.id,
    required super.listId,
    required super.title,
    this.quantity,
    this.unit,
    this.category = MarketCatalog.uncategorized,
    this.estimatedPrice,
    this.isPurchased = false,
    this.notes,
  });

  @override
  ListType get listType => ListType.market;

  factory MarketItemData.fromTodoItem(TodoItem item) => MarketItemData(
    id: item.id,
    listId: item.listId,
    title: item.title,
    quantity: item.quantity,
    unit: item.unit,
    category: MarketCatalog.categories.contains(item.category)
        ? item.category!
        : MarketCatalog.uncategorized,
    estimatedPrice: item.price,
    isPurchased: item.isCompleted,
    notes: item.notes,
  );
}

class ShoppingItemData extends TypedItemData {
  final String? imageUrl;
  final double? estimatedPrice;
  final ItemPriority? priority;
  final String? productUrl;
  final String? store;
  final String? notes;
  final ShoppingItemStatus status;

  const ShoppingItemData({
    required super.id,
    required super.listId,
    required super.title,
    this.imageUrl,
    this.estimatedPrice,
    this.priority,
    this.productUrl,
    this.store,
    this.notes,
    this.status = ShoppingItemStatus.pending,
  });

  @override
  ListType get listType => ListType.shopping;

  bool get isPurchased => status == ShoppingItemStatus.purchased;
  bool get isDiscarded => status == ShoppingItemStatus.discarded;

  factory ShoppingItemData.fromTodoItem(TodoItem item) => ShoppingItemData(
    id: item.id,
    listId: item.listId,
    title: item.title,
    imageUrl: item.imageUrl,
    estimatedPrice: item.price,
    priority: item.priority,
    productUrl: item.url,
    store: item.store,
    notes: item.notes,
    status: ShoppingItemStatus.fromItem(item),
  );
}

class OptionItemData extends TypedItemData {
  final String? description;
  final double? price;
  final Map<String, String> attributes;
  final String? pros;
  final String? cons;
  final int? rating;
  final String? url;
  final String? imageUrl;
  final String? notes;
  final bool isFavorite;
  final OptionDecisionStatus status;

  const OptionItemData({
    required super.id,
    required super.listId,
    required super.title,
    this.description,
    this.price,
    this.attributes = const {},
    this.pros,
    this.cons,
    this.rating,
    this.url,
    this.imageUrl,
    this.notes,
    this.isFavorite = false,
    this.status = OptionDecisionStatus.considering,
  });

  @override
  ListType get listType => ListType.options;

  bool get isSelectedDecision => status == OptionDecisionStatus.selected;
  bool get isFinalist => status == OptionDecisionStatus.finalist;
  bool get isDiscarded => status == OptionDecisionStatus.discarded;

  factory OptionItemData.fromTodoItem(TodoItem item) => OptionItemData(
    id: item.id,
    listId: item.listId,
    title: item.title,
    description: item.description,
    price: item.price,
    attributes: Map<String, String>.unmodifiable(item.attributes),
    pros: item.pros,
    cons: item.cons,
    rating: item.rating,
    url: item.url,
    imageUrl: item.imageUrl,
    notes: item.notes,
    isFavorite: item.isFavorite,
    status: OptionDecisionStatus.fromItem(item),
  );
}

class TaskItemData extends TypedItemData {
  final String? description;
  final DateTime? dueDate;
  final ItemPriority? priority;
  final bool isCompleted;
  final bool isInProgress;
  final List<Subtask> subtasks;
  final String? notes;

  const TaskItemData({
    required super.id,
    required super.listId,
    required super.title,
    this.description,
    this.dueDate,
    this.priority,
    this.isCompleted = false,
    this.isInProgress = false,
    this.subtasks = const [],
    this.notes,
  });

  @override
  ListType get listType => ListType.tasks;

  int get completedSubtasksCount =>
      subtasks.where((subtask) => subtask.isCompleted).length;

  factory TaskItemData.fromTodoItem(TodoItem item) => TaskItemData(
    id: item.id,
    listId: item.listId,
    title: item.title,
    description: item.description,
    dueDate: item.dueDate,
    priority: item.priority,
    isCompleted: item.isCompleted,
    isInProgress: item.isInProgress,
    subtasks: List<Subtask>.unmodifiable(item.subtasks),
    notes: item.notes,
  );
}

class CustomItemData extends TypedItemData {
  final String? description;
  final String? notes;
  final bool isCompleted;

  const CustomItemData({
    required super.id,
    required super.listId,
    required super.title,
    this.description,
    this.notes,
    this.isCompleted = false,
  });

  @override
  ListType get listType => ListType.custom;

  factory CustomItemData.fromTodoItem(TodoItem item) => CustomItemData(
    id: item.id,
    listId: item.listId,
    title: item.title,
    description: item.description,
    notes: item.notes,
    isCompleted: item.isCompleted,
  );
}
